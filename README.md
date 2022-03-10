Herein lies attempts to map logical and physical data models at DfE

## Goals

1. A "logical" data model: a model of the real-world/problem-domain objects and how they relate.

2. A "physical" data model: a model of what data repositories we have and what
   aspects of the real-world objects are stored in each, and how the data flows
   between them work.

3. The relationship between them, showing what physical databases *represent* what logical objects.

## How To Build The Maps

You can view the source data for the map so far in `src/model.rb`, which is a Ruby script that generates:

1. Multiple graph models in the `out` directory, in [GraphViz](https://graphviz.org/) format
2. A `representations.html` file listing finer detail on how logical objects are realised in physical databases.

It does this by using code in `src/engine.rb`.

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
make view-representations
```

...generates corresponding SVG files in `out` and attempts to view them with `inkview` (part of the [Inkscape](https://inkscape.org/) package).

### The Generated Maps

#### Key (`out/logical.svg`, `out/logical.png`, `make view-key`)

Shows the symbols used for different types of objects and the arrows between them.

#### Logical (`out/logical.svg`, `out/logical.png`, `make view-logical`)

This shows "logical objects": the actual real-world objects we deal with, such as people, schools, and applications for courses.

It also shows the links between them - for instance an application for a course has a link to the person applying, and to the course being applied for.

#### Physical (`out/physical.svg`, `out/physical.png`, `make view-physical`)

This shows physical databases.

It also shows where data is duplicated between them by some process.

#### Representations (`out/representations.svg`, `out/representations.png`, `make view-representations`)

This shows what physical databases store information about what logical objects. So it shows the objects and the databases, and arrows between them indicating where data is stored.

Where knows, the head of the arrow is decorated with the name of the table in the physical database that stores the information.

#### Representations (detail) (`out/representations.html`)

This table shows the same information as the Representations chart, but with further detail, and in a tabular form; it indicates what fields in the table in the physical databases are used to identify that real-world object. These "key fields" can either be pure primary keys that can be relied upon, optional keys that are not always present, or fuzzy keys that may or may not be correct or particularly unique, but may be of use.

#### Actors and Databases (`out/actors_dbs.svg`, `out/actors_dbs.png`, `make view-actors`)

This shows what services or other software agents use what physical databases. It also shows where actors use each other to access data, via an API.

## The Source (`src/model.rb`)

This file is where the master data for the map is contained. Edit this file to make changes to the map.

It's a Ruby source code file, but you don't need to know Ruby to edit it; you can just treat it as plain text. See inside the file for details on the format.

If you have information to contribute to the Map and the thought of editing a Ruby source code file in a git repo is daunting, please just drop the Data Insight Team a message and we'll make the changes for you (or teach you how to edit Ruby source code files in git repos, if you'd like to learn!).

## The Rendering Engine (`src/engine.rb`, `Makefile`)

The `Makefile` contains the top-level instructions to generate all the outputs, including running the Ruby code, running GraphViz, and preparing some static resources (the key and index page).

`src/engine.rb` contains the Ruby code used to convert the information in `src/model.rb` into HTML and GraphViz-format files.

## Static Resources (`src/key.dot`, `src/index.html`)

The key and the index page with help for viewers of the maps. The `Makefile`
renders the key into SVG, and just copies the index page over into `out`.

## Submitting Changes

Please, please do submit improvements if you can! Either create a pull request on this repo if you're happy editing `model.rb`, or ask a friendly Ruby developer to do it for you, or contact the Data Insight Team. Your contributions are what make the map a useful resource. Thank you!

## Thoughts and TODOs

### Better capture the complexity of things like Person

Ok, so we have lots of different things in databases that are... *aspects* of a
person. Like, `candidate` and `user`. I've mapped them all to the logical object
of a "Person" because people are what exist in the real world, but it feels like
there's a missing stage here - some logical object corresponding to the "role"
of a person as a candidate or a user that actually gets implemented in the
DB. It would be nice to have that to reflect that multiple databases tables
implement any particular "role", but there's nothing in the map to say that
these tables all represent that "role" other than that they're all listed as
representations of a "person", which can also mean weaker links like those
between tables representing `candidate` and `user`.

Would introducing a "subtype" notion in the logical model be worth the complexity?

### `index.html` is ugly

It needs some CSS to make it look nicer.

## GOV.UK PaaS set-up

The application is called bat-data-map and is supported by the Staticfile buildpack. It is deployed in the space bat-qa, in the dfe organisation.

There is no cdn-route service, we simply use the default .london.cloudapps.digital domain.
i.e. https://bat-data-map.london.cloudapps.digital/

### Deployment

A github action workflow 'Deploy to GOV.UK PaaS' is triggered on push to master.
This configures the deployment environment, and runs a 'make all' before pushing the updates to PaaS.

The PaaS service account credentials are stored in Azure keyvault.
We have an Azure service principal (s121d01-keyvault-readonly-access) and we store the service principal client secret in github secrets, so the workflow can connect to AZ and collect the PaaS credentials.
This is configured as per,
https://technical-guidance.education.gov.uk/infrastructure/hosting/azure-cip/#service-principal

There is currently only one environment, and any changes should be previewed locally.
