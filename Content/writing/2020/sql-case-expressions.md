<style>
.footer {display: none;}
</style>

# SQL peculiarities in db2 (on the AS400), part ?

SQL's `CASE` expression. Turns out that it's an expression, not a statement, so… it's supposed to only be allowed in expression contexts, IE the right-hand side of stuff.

```SQL
WHERE 1 = CASE :student_id WHEN '123' THEN 1 ELSE 0 END
```

Postgres allows you to do something like the following:

```SQL
WHERE CASE :student_id WHEN '123' THEN 1 = 1 ELSE 0 = 1 END
```

that is, the entire CASE can evaluate to a boolean value, not just a single value, which db2 requires.

TODO: document the occasional `CAST(? as varchar(100))` block required by db2.
