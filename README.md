Herein lies attempts to map logical and physical data models at DfE

## Goals

1. A "logical" data model: a model of the real-world/problem-domain objects and how they relate.

2. A "physical" data model: a model of what data repositories we have and what
   aspects of the real-world objects are stored in each, and how the data flows
   between them work.

## How To

You can view the map so far in `src/model.rb`, which is a Ruby script that generates multiple graph models in the `out` directory, in [GraphViz](https://graphviz.org/) format, and a `realisations.html` file listing finer detail on how logical objects are realised in physical databases.

If you have `make` and GraphViz installed, you can also turn it into various output forms with the following commands:

```
make all
```

...generates SVG and PNG files in `out`

```
make view-key
make view-actors
make view-logical
make view-physical
make view-realisations
```

...generates corresponding SVG files in `out` and attempts to view them with `inkview` (part of the [Inkscape](https://inkscape.org/) package).

### The Maps

#### Key (`out/logical.svg`, `out/logical.png`, `make view-key`)

Shows the symbols used for different types of objects and the arrows between them.

#### Logical (`out/logical.svg`, `out/logical.png`, `make view-logical`)

This shows "logical objects": the actual real-world objects we deal with, such as people, schools, and applications for courses.

It also shows the links between them - for instance an application for a course has a link to the person applying, and to the course being applied for.

#### Physical (`out/physical.svg`, `out/physical.png`, `make view-physical`)

This shows physical databases.

It also shows where data is duplicated between them by some process.

#### Realisations (`out/realisations.svg`, `out/realisations.png`, `make view-realisations`)

This shows what physical databases store information about what logical objects. So it shows the objects and the databases, and arrows between them indicating where data is stored.

Where knows, the head of the arrow is decorated with the name of the table in the physical database that stores the information.

#### Realisations (detail) (`out/realisations.html`)

This table shows the same information as the Realisations chart, but with further detail, and in a tabular form; it indicates what fields in the table in the physical databases are used to identify that real-world object. These "key fields" can either be pure primary keys that can be relied upon, optional keys that are not always present, or fuzzy keys that may or may not be correct or particularly unique, but may be of use.

#### Actors and Databases (`out/actors_dbs.svg`, `out/actors_dbs.png`, `make view-actors`)

This shows what services or other software agents use what physical databases. It also shows where actors use each other to access data, via an API.

## Thoughts and TODOs

### Better capture the complexity of things like Person

Ok, so we have lots of different things in databases that are... *aspects* of a person. Like, `candidate` and `user`. I've mapped them all to the logical object of a "Person" because people are what exist in the real world, but it feels like there's a missing stage here - some logical object corresponding to the "role" of a person as a candidate or a user that actually gets implemented in the DB. It would be nice to have that to reflect that multiple databases tables implement any particular "role", but there's nothing in the map to say that these tables all represent that "role" other than that they're all listed as representations of a "person", which can also mean weaker links like those between tables representing `candidate` and `user`.

### Think of a better term than "realisation". "Representation"?

### Expand acronyms for new people (DQT etc)

### Ordering the HTML realisations table

We sort by the first column, need a sort order for the second column as well. Claire said:

"E.g. Provider users in Register, Publish and Manage should all be grouped near each other. It's analysis we've done before to see who has access to 1, 2 or 3 of those services."
