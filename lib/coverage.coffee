fs = require 'fs-plus'
path = require 'path'

CoveragePanelView = require './coverage-panel-view'
CoverageStatusView = require './coverage-status-view'

module.exports =
  configDefaults:
    refreshOnFileChange: true

  coveragePanelView: null
  coverageStatusView: null
  coverageFile: null
  pathWatcher: null

  activate: (state) ->
    @coverageFile = path.resolve(atom.project.path, "coverage/coverage.json") if atom.project.path
    @coveragePanelView = new CoveragePanelView

    # initialize the pathwatcher if its enabled in the options and the coverage file exists
    if @coverageFile and atom.config.get("coverage.refreshOnFileChange") and fs.existsSync(@coverageFile)
      @pathWatcher = fs.watch(@coverageFile, @update)

    # add the status bar and refresh the coverage after all packages are loaded
    atom.packages.once "activated", =>
      if atom.workspaceView.statusBar
        @coverageStatusView = new CoverageStatusView(@coveragePanelView)
        atom.workspaceView.statusBar.appendLeft @coverageStatusView
        @update()

    # commands
    atom.workspaceView.command "coverage:toggle", => @coveragePanelView.toggle()
    atom.workspaceView.command "coverage:refresh", => @update()

    # update coverage
    @update()

  update: ->
    if @coverageFile and fs.existsSync(@coverageFile)
      fs.readFile @coverageFile, "utf8", ((error, data) ->
        return if error

        data = JSON.parse(data)

        @updatePanelView data.metrics, data.files
        @updateStatusBar data.metrics
      ).bind(this)
    else
      @coverageStatusView?.notfound()

  updatePanelView: (project, files) ->
    @coveragePanelView?.update project, files

  updateStatusBar: (project) ->
    @coverageStatusView?.update Number(project.covered_percent.toFixed(2))

  deactivate: ->
    @coveragePanelView?.destroy()
    @coveragePanelView = null

    @coverageStatusView?.destroy()
    @coverageStatusView = null

    @coverageFile = null

    @pathWatcher?.close()
