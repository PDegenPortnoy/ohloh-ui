# This is a manifest file that'll be compiled into application.js, which will include all the files
# listed below.
#
# Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
# or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
#
# It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
# compiled file.
#
# Read Sprockets README (https:#github.com/sstephenson/sprockets#sprockets-directives) for details
# about supported directives.
#
#= require jquery
#= require jquery_ujs
#= require jquery-ui
#= require underscore-min
#= require chosen.min
#= require app
#= require api/timeline-api.js
#= require api/scripts/timeline.js
#= require api/scripts/util/platform.js
#= require api/scripts/util/debug.js
#= require api/scripts/util/xmlhttp.js
#= require api/scripts/util/dom.js
#= require api/scripts/util/graphics.js
#= require api/scripts/util/date-time.js
#= require api/scripts/util/data-structure.js
#= require api/scripts/units.js
#= require api/scripts/themes.js
#= require api/scripts/ethers.js
#= require api/scripts/ether-painters.js
#= require api/scripts/labellers.js
#= require api/scripts/sources.js
#= require api/scripts/layouts.js
#= require api/scripts/painters.js
#= require api/scripts/decorators.js
#= require api/scripts/l10n/en/labellers.js
#= require api/scripts/l10n/en/timeline.js

#= require_tree .
#= require twitter/bootstrap
#= require d3.min
#= require highcharts/highstock
#= require highcharts/highcharts-more
#= require highcharts/solid-gauge
#= require tagcloud
#= require ace-element.min


$(document).on 'page:change', ->
  Edit.init()
  StackVerb.init()
  StackShow.init()
  Expander.init()
  PopupClose.init()
  OrganizationPictogram.init()
  GaugeProgress.init()
  OrgsFilter.init()
  Cocomo.init()
  ProjectForm.init()
  OrgClaimProject.init()
  new App.CheckAvailiability($('input.check-availability'))
  App.TagCloud.init()

# Remove the following trigger when TurboLinks are re-enabled
$(document).ready ->
  $(document).trigger 'page:change'
