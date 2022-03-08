require_relative 'engine'

## The data

map = Map.new()

# Logical objects, and how they link to each other

# Style guide:

# 1) Don't explicitly represent the storing of history. For instance, we want a
# history of lead school relationships from a provider so we can know who WAS
# the lead school or who is SCHEDULED to be the lead school, but we don't
# explicitly show this in the diagram. However, things like employments that
# have a start/end as well as some other useful properties (such as the role) we
# DO explicitly show, even though their start/end forms a history, as there's
# other imoprtant state to show, or a potential many-to-many relationship (as is
# the case with school experience).

# 2) Avoid cluttering the diagram with technical details: keep it problem-domain
# focused. Omit obvious uninteresting fields (names, etc). Summarise groups of
# fields ("contact details" rather than address1, address2, ...)

# 3) We can skim over some minor problem-domain details, like the fact that
# applications have referees which are also people, if they're not particularly
# interesting; this is a value judgement which should be re-assessed if that
# fact BECOMES interesting later.

# Maybe a "site"? "establishment"? "location"?
map.logical_object("location","Location",[["urn","URN",true]])

map.logical_object("itt-provider","ITT Provider",[["lead","Lead school",false]])
map.logical_link("itt-provider","lead","location")

map.logical_object("accredited-provider","Accredited Provider (HEI/SCITT)",[])

map.logical_object("person","Person",[["trn","TRN",true]])

map.logical_object("employment","Employment",["start / end","role",["employee","Employee",false],["employer","Employer",false]])
map.logical_link("employment","employee","person")
map.logical_link("employment","employer","itt-provider")
map.logical_link("employment","employer","location")

map.logical_object("vacancy","Vacancy",[["employer","Employer"]])
map.logical_link("vacancy","employer","location")

map.logical_object("job-application","Job application",[["applicant","Applicant"],["vacancy","Vacancy"],["job","Resulting job",true]])
map.logical_link("job-application","applicant","person")
map.logical_link("job-application","vacancy","vacancy")
map.logical_link("job-application","job","employment")

map.logical_object("school-experience","School Experience Trial",["start / end",["person","Person"],["school","School"]])
map.logical_link("school-experience","person","person")
map.logical_link("school-experience","school","location")

map.logical_object("itt-subject","ITT Subject",["funding / bursary info"])

map.logical_object("itt-course","ITT Course",[["provider","Provider"],["accreditor","Accreditor"],["subject","Subject"]])
map.logical_link("itt-course","provider","itt-provider")
map.logical_link("itt-course","accreditor","accredited-provider")
map.logical_link("itt-course","subject","itt-subject")

map.logical_object("itt-application","ITT Application",[["applicant","Applicatn"],["course","Course"],"status"])
map.logical_link("itt-application","applicant","person")
map.logical_link("itt-application","course","itt-course")

# Physical databases, synchronisations between them, and representations of logical objects in them

# Synchronisation done within an existing component (like the updating of
# bigquery by the services) or by a dedicated data synchronising system should
# be indicated here; but any synchronisation that involves more complicated
# process should probably be indicated by an actor that talks to source and sink
# databases. Use your judgement to decide what would make for a clearer diagram.

map.physical_database("git crm", "GIT (Get Into Teaching) CRM (Customer Relationship Manager)")
map.representation("person","git crm")

map.physical_database("publish db", "Publish DB")
map.representation("itt-provider","publish db","Provider",["code"])
map.representation("itt-course","publish db","Course",["code","uuid"])
map.representation("itt-subject","publish db","Subject",["code","name~"])
map.representation("location","publish db", "Site", ["uuid"])
map.representation("person","publish db","ProviderUser",["dfe_sign_in_uid"])

map.physical_database("experience db", "Get School Experience DB")
map.physical_synch("gias db","experience db","nightly dump")
map.representation("person","experience db")
map.representation("location","experience db")
map.representation("school-experience","experience db")

map.physical_database("apply db", "Apply DB")
map.representation("person","apply db","ProviderUser",["dfe_sign_in_uid"])
map.representation("person","apply db","SupportUser",["dfe_sign_in_uid"])
map.representation("person","apply db","Candidate",["email_address~"])
map.representation("itt-provider","apply db","Provider",["code"])
map.representation("itt-course","apply db","Course",["code","uuid"])
map.representation("itt-subject","apply db","Subject",["code","name~"])
map.representation("itt-application","apply db","ApplicationChoice",[]) # Maybe provider_ids is the application ID as used by the provider?

map.physical_database("register db", "Register DB")
map.physical_synch("gias db","register db","manual dump")
map.representation("person","register db","Trainee",["trainee_id","hesa_id","provider_id","trn?","dttp_id?","email~"])
map.representation("person","register db","User",["dfe_sign_in_uid","dttp_id?"])
map.representation("itt-provider","register db","Provider",["dttp_id?","ukprn"])
map.representation("itt-course","register db","Course",["uuid","code"])
map.representation("itt-subject","register db","Subject",["code","name~"])
map.representation("itt-application","register db","ApplyApplication",["apply_id"])
map.representation("location","register db","School",["urn"])

map.physical_database("dttp", "DTTP (Database of Trainee Teachers and Providers)")
map.physical_synch("dttp","dqt","TRN (Teacher Reference Number) allocation")
map.physical_synch("dttp","dqt","QTS (Qualified Teacher Status) award")
map.representation("itt-provider","dttp")
map.representation("person","dttp")

map.physical_database("dqt", "DQT (Database of Qualified Teachers)")
map.representation("person","dqt")

map.physical_database("tps db", "TPS (Teacher Pension Service) DB")
map.representation("person","tps db")

map.physical_database("gias db", "GIAS (Get Information About Schools) DB")
map.representation("location","gias db")

map.physical_database("bigquery", "BigQuery")
map.physical_synch("publish db","bigquery","stream")
map.physical_synch("apply db","bigquery","stream")
map.physical_synch("register db","bigquery","stream")
map.representation("itt-application","bigquery","application_choices",["application_choice_id"])
map.representation("person","bigquery","candidates",["candidate_id"])
map.representation("itt-course","bigquery","courses_apply",["course_id","code","uuid"])
map.representation("person","bigquery","organisation_user",["user_id"])
map.representation("person","bigquery","provider_users",["provider_user_id","dfe_sign_in_uid"])
map.representation("itt-provider","bigquery","providers_apply",["provider_id"]) # Is code a key?
map.representation("itt-application","bigquery","register_apply_applications",["id","apply_id"])
map.representation("itt-course","bigquery","register_courses",["id","course_code","uuid"])
map.representation("itt-provider","bigquery","register_dttp_providers",["id","dttp_id?","name~","ukprn"])
map.representation("location","bigquery","register_dttp_schools",["id","urn"])
map.representation("itt-provider","bigquery","register_providers",["id","dttp_id?","name~","ukprn"])
map.representation("location","bigquery","register_schools",["id","urn"])
map.representation("itt-subject","bigquery","register_subjects",["id","code","name~"])
map.representation("person","bigquery","register_trainees",["id","dttp_id"])
map.representation("person","bigquery","register_users",["id","dfe_sign_in_uid","dttp_id?"])
map.representation("location","bigquery","sites_apply",["site_id","code"])
map.representation("itt-subject","bigquery","subject_publish_api",["subject_id","subject_code","subject_name"])
map.representation("itt-subject","bigquery","subjects_apply",["subject_id","name","code"])
map.representation("person","bigquery","user",["user_id"])

# Actors, and what physical DBs and other actors they use

map.actor("git", "GIT (Get Into Teaching)")
map.actor_uses("git","git crm")

map.actor("find", "Find Teacher Training")
map.actor_uses("find","publish apis")

map.actor("apply", "Apply for Teacher Training")
map.actor_uses("apply","apply db")
map.actor_uses("apply","publish")

map.actor("manage", "Manage Applications for Teacher Training")
map.actor_uses("manage","apply db")

map.actor("publish", "Publish Teacher Training Courses")
map.actor_uses("publish","publish apis")

map.actor("publish apis")
map.actor_uses("publish apis","publish db")

map.actor("tps", "Teacher Pension Service")
map.actor_uses("tps","tps db")

map.actor("funding")
map.actor_uses("funding","dttp")

map.actor("nao","National Audit Office")
map.actor_uses("nao","dttp")

map.actor("mra","Market Regulation Authority")
map.actor_uses("mra","dttp")

map.actor("corpa","Corporate Assurance")
map.actor_uses("corpa","dttp")

map.actor("get experience","Get Experience In Schools")
map.actor_uses("get experience","experience db")

map.actor("tad","Teacher Analysis Division")
map.actor_uses("tad","apply db")
map.actor_uses("tad","dttp")
map.actor_uses("tad","dqt")

map.actor("gias","Get Information About Schools")
map.actor_uses("gias","gias db")

map.actor("register", "Register Trainee Teachers")
map.actor_uses("register","register db")

map.actor("hesa","Higher Education Standards Authority")
map.actor_uses("hesa","dttp")
map.actor_uses("hesa","dqt")

map.actor("claim")
map.actor_uses("claim","dqt")

map.actor("dashboards","Teacher Services Dashboards")
map.actor_uses("dashboards","bigquery")

## Final generation

map.generate_all_views()
