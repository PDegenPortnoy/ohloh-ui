ProjectVulnerabilityVersionChart =
  init: () ->
    return if $('#vulnerability_version_chart').length == 0

    $.ajax
      url: $('#vulnerability_version_chart').data('src')
      cache: false
      success: (data) ->
        return if (data == null)
        chart = new Highcharts.Chart(data);

$(document).on 'page:change', ->
  ProjectVulnerabilityVersionChart.init()
  $('tr.nvd_link').click ->
    window.open($(this).data('nvd-link'), '_blank')

  $('span#read_more a, span#read_less a').click (e) ->
    e.stopPropagation()
    $(this).closest('td').find('span').toggle()
