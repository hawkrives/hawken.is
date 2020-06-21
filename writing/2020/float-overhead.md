# Python floats

tonight in Degreepath… I reduced the amount of memory needed, by removing the list of duration floats that it was using to compute the average loop duration. (no, I don't know why I was doing this.)

a python float = 24 bytes in bits => 192 bits
iters = 1,200,000,000

(float * iters) in GB => 28.8 GB

that's right, for a 1.2 billion loop audit, we're using 28+ gigabytes of RAM, just to store the audit loop durations.

da4c35c6 should reduce that overhead to, oh, about 24 bytes.

---

I was like, why do I have a memory leak

---

and I was chatting with nolan and realized, oh, I'm storing a float per loop iteration, I wonder how big those are

---

> [da4c35c6](https://github.com/degreepath/auditor/commit/da4c35c665a7b3c881c3978f2954d0381ea48e25) should reduce that overhead to, oh, about 24 bytes.

---

"In CPython, every object begins with a reference count (of type ssize_t, i.e. a machine word) and a pointer to the type object for that object, which is necessary to be able to do any operations (e.g. invoke a method) on the object. That's two machine words right there off the bat, before you even start to talk about the data contained in the object. After that header comes a variable amount of data; in the case of a float object, it's just a C double value directly, so another eight bytes. For a 32 bit CPython, that's 4 + 4 + 8 = 16 bytes, for a 64 bit CPython, that's 8 + 8 + 8 = 24 bytes. Note that CPython can also be configured for debug builds, which adds two more pointers to that common header shared by all objects, which are used to form a doubly linked list of all objects on the heap, which can be used to track down reference counting bugs."

---

In short, instead of storing [dur, dur, dur] and averaging that list, I just … recompute (now - start) / count each time I need it

---

which is also fewer operations, because it's only needed for progress messages (default every 1,000 iters) and the final output

And we’ve already shown that 1.2 billion floats is 28.8GB… 