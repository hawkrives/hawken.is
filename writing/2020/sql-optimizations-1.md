# SQL optimizations in SIS

> This document is derived from an email I wrote today.

I've been optimizing the number of queries on the SIS course registration page.

Currently, we make one giant query for all of the "matching" classes, with an extra row for each faculty member who teaches the class. So, a course with two sections, each with two instructors, would return four rows from `fetch_matching_courses`.

The rows are deduplicated by a `<cfoutput query="fetch_matching_courses" group="CLBID">` construct, which ignores the instructors and outputs one row per CLBID. That's OK.

Within each matching class, there are several pieces of information that are bound to multiple other rows in the database:

- Instructors (as detailed above)
- Notes
- Prerequisites
- Meeting Rooms/Times
- GE Requirements
- Associated lab/discussion courses

For each of those, except for the instructors, we currently make an extra query back to the database to fetch the matching items.

In system design, there's a topic called "N + 1 Queries" – feel free to skip this section if you know of it; I'm just writing down a bunch of disjointed thoughts here – which is considered to be a suboptimal design for querying things. This is due to the inherent network overhead of querying an out-of-process database (SQLite is an exception, as it's bundled into the process that calls it). The N + 1 query problem is when, for each row in your result set, you request more data from the database. For example, a set of articles, and then you might request the tags for each article:

```cfml
<cfquery name="articles">
SELECT article_id, title FROM articles WHERE published > now() - '1 week'
</cfquery>

<cfoutput query="articles">
  <cfquery name="tags">
    SELECT tag_id, name FROM article_tags WHERE article_id = <cfqueryparam value="#articles.article_id#">
  </cfquery>
</cfoutput>
```

If we assume even a 1ms network overhead for talking to the database, then that's … 1, 2, 3, 4, 5+ queries per output row, which if someone searches for a 100-class result list – maybe, say, all WRI courses – then that's at least 100ms spent doing nothing but waiting for the network to talk to INEZ.

Now, we do also have to factor in the ColdFusion cached queries, since we use those a fair amount. I still want to check in on how many queries we allow to be cached, and, like, the cache hit ratio on them? But I think we can safely assume that _most_ searches won't have all 5 queries hit the database. However, the first ones will, probably every morning, since we only cache these results for 6 hours.

So. All that is to say, I've been working on ways to reduce the number of queries performed within the output loop.

I don't want to mimic what we do for instructors – as nice as that is, to do a Query-of-Queries for each type of data, I believe that once we add in GEs, and notes, and meeting rooms, we'd be producing something like 20 times the number of rows we actually want, and I don't think that INEZ would be especially happy about that.

So I've been experimenting with a few different approaches. 

## For GE requirements: 

1. Perform a listagg of the GEreqs on the course query, to produce a delimited list like `WRI,FOL-N`
2. Find all of the GE reqs, then store them in a lookup table of [GECODE: PDF url]
3. For each course, `<cfloop list>` over that delimited list, then look up the URL in the lookup table.

That's one extra query, total, which can be cached easily, and some struct lookups.

## For instructors:

I think I want to do something similar: listagg the PPNUMs, then look up all active instructors, then `<cfloop>` and do a struct lookup.

## For meeting times and course notes:

And maybe I should do the same approach – look up and cache the list of all meeting times for the current term, paying the cost of a big query exactly once per 6 hours, then store them in a lookup table (or do a QoQ?) and look them up by meeting-ID.

Same for notes.

I was experimenting with doing an "all notes" query, with CLBIDs, but I realized that (a) that'd be a bunch of different query plans on the db2 side[^1], and (b) it wouldn't cache very well, because each query would result in different CLBIDs being passed in (especially since we exclude registered CLBIDs from the search results).

I think I want to experiment with what I proposed above, now that I've reflected on it some more.

## For associated courses:

For each associated course…

- We call helper-check-time-conflict for each (registered, associated) CLBID pair, and again for the (parent, associated) pair [to prevent class and assoc. lab time conflicts]. helper-check-time-conflict makes two queries, one for each CLBID passed in, which are cached for 6 hours, and then checks for time conflicts with some CFML logic.

- Then we query for the meeting times, and we do a QoQ on `fetch_matching_courses` to find the instructors.

… and we build up the set of <option> tags that get shown to the student.

So that's N*M + N queries, in the worst case, for each parent course with associated courses, where N is the number of associates, and M is the number of registered courses on the student. However, once a given course has been looked up, this data is cached. 

But, there's also the uncached query that looks up the list of associated courses, and I don't think that we can cache it, because we need to check class size limits.

My best idea for reducing the number of queries here is to change `required_other_course_info` to be a Query-of-Queries, which I think is plausible; it's selecting the same columns that `fetch_matching_courses` does, and it's really looking for a subset of the matched courses, currently. Alternately, it should be feasible to do a single large query at the outset, right after `fetch_matching_courses`, which selects the associated courses for anything found by `fetch_matching_courses`, and then QoQ that query instead. Experimentation needed!

And that leaves us with…

## Prerequisites

Each course calls helper-check-prereqs, which does at least one lookup (to fetch the applicable rules, if any). I have now started caching this query, and the other queries that just look at RCREQT/RCRULS, for 6 hours each.

helper-check-prereqs queries for additional rules, then calls helper-evaluate-rule for each rule that it finds. (This can be a recursive set of calls, unfortunately.)

helper-evaluate-rule starts off with a query, to look up what the requirement are actually wants. Each potential column results in additional queries being run, to look up things like "has the student taken this course" or "is the student declared with this major", and so on.

I edited this file today to add the "cachedafter" attribute to these data lookups. When helper-evaluate-rule is first called, it sets a REQUEST-scoped variable called `REQUEST.prereqs_cachedafter` to the current timestamp. What I'm doing here is to allow any future queries against this information _in this request_ to use the cached data, but to avoid any subsequent queries from seeing stale information. This unfortunately doesn't avoid issues with concurrent requests (from the same student) re-using the cached data, but I don't think we can really do anything about that at this time.

According to [cursory internet searches](https://www.coldfusionmuse.com/index.cfm/2008/3/18/cachedafter), ColdFusion will automatically discard the old cached information when I change the `cachedafter` parameter, so it won't re-use stale data between requests.

By doing this data caching, I dropped the time taken to evaluate ART 350 (which has 370 possible rules) from ~2s to ~0.1s.

----

So! That's what's been on my mind over the weekend and for the past few days. I hope that this mostly-unfiltered blog post is helpful in some way!

I suppose the summary is, I am working to reduce the number of database queries we perform per row of the course search results from 5+ queries to approx. 1 query per row, if that; ideally, 0 extra INEZ queries per row.

I also want to remove the duplicate-row-per-faculty issue from the main query, but that's tangential to the primary goal here, unless our IBM guy identifies it as actually being an issue.

---

Update 1: I have successfully replaced the instructor QoQ lookup (the one that generated duplicate rows) with QoQ lookup from a "give me all the instructors who taught something in 2020-3" query. Seems about the same speed, but I have high hopes that it will scale to notes and times, too.

[^1]: ColdFusion automatically "prepares" any query that you give it, which allows subsequent runs of the same SQL text to happen faster because they don't need to be parsed from a string again. Our DB2 consultant identified "large numbers of query plans" as being detrimental to the performance in the registration page, so I've been keeping that in mind. Doing `WHERE column IN (<cfqueryparam list=yes>)` translates to `WHERE column IN (?, ?, ?, ?, …, ?)`, with one `?` for each value in the list. What this means, practically, is that each size of list that we pass in generates a new prepared query on the database side.
