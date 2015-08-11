xml.data do
  @daily_commits.each do |commit|
    div_id = "commit_#{ commit['time'].to_i }"
    attributes = {
      start: commit['time'].strftime("%b %d %Y %H:%M:%S %Z"),
      ajaxDescription:
      event_details_project_commit_url(project_id: @project.id, contributor_id: params[:contributor_id], time: div_id),
       title: commit['count'].to_i == 1 ? (commit['comment'] || '').truncate(40) : "#{ commit['count'] } Commits"
     }
    attributes[:icon] = '/timeline/images/dull-blue-circle-3.png' if commit['count'].to_i > 1
    xml.event(attributes, "<img src='/timeline/images/spinner.gif' style='vertical-align:middle;' />")
  end
end
