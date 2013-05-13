class ArchivesSpaceService < Sinatra::Base


  Endpoint.post('/subjects/:subject_id')
    .description("Update a Subject")
    .params(["subject_id", Integer, "The subject ID"],
            ["subject", JSONModel(:subject), "The subject data to update", :body => true])
    .nopermissionsyet
    .returns([200, :updated]) \
  do
    handle_update(Subject, :subject_id, :subject)
  end


  Endpoint.post('/subjects')
    .description("Create a Subject")
    .params(["subject", JSONModel(:subject), "The subject data to create", :body => true])
    .nopermissionsyet
    .returns([200, :created]) \
  do
    handle_create(Subject, :subject)
  end


  Endpoint.get('/subjects')
    .description("Get a list of Subjects")
    .params()
    .paginated(true)
    .nopermissionsyet
    .returns([200, "[(:subject)]"]) \
  do
    handle_listing(Subject, params)
  end


  Endpoint.get('/subjects/:subject_id')
    .description("Get a Subject by ID")
    .params(["subject_id", Integer, "The subject ID"])
    .nopermissionsyet
    .returns([200, "(:subject)"]) \
  do
    json_response(Subject.to_jsonmodel(params[:subject_id]))
  end


  Endpoint.delete('/subjects/:subject_id')
    .description("Delete a Subject")
    .params(["subject_id", Integer, "The subject ID to delete"])
    .nopermissionsyet
    .returns([200, :deleted]) \
  do
    handle_delete(Subject, params[:subject_id])
  end

end
