window.TabsEditingDescriptorModel =
  addSave : (id, tabName, saveFunction) ->
    ###
    Function that register save functions of every tab.
    ###
    @init(id)
    @modules[id].modelUpdate[tabName] = saveFunction

  addOnSwitch : (id, tabName, onSwitchFunction) ->
    ###
    Function that register functions invoked when switching
    to particular tab.
    ###
    @init(id)
    @modules[id].tabSwitch[tabName] = onSwitchFunction

  updateValue : (id, tabName) ->
    ###
    Function that invokes when switching tabs.
    It ensures that data from previous tab is stored.
    If new tab need this data, it should retrieve it from 
    stored value.
    ###
    @init(id)
    saveFunction = @modules[id]['modelUpdate'][tabName]
    @modules[id]['value'] =saveFunction()  if $.isFunction(saveFunction)

  getValue : (id, tabName) ->
    ### 
    Retrieves stored data on save.
    1. When we switching tabs - previous tab data is always saved to @[id].value
    2. If current tab have registered save method, it should be invoked 1st.
    (If we have edited in 1st tab, then switched to 2nd, 2nd tab should
    care about getting data from @[id].value in onSwitch.)
    ###
    if not @modules[id]
      return null
    if $.isFunction(@modules[id]['modelUpdate'][tabName])
      @modules[id]['modelUpdate'][tabName]()
    else
      if typeof @modules[id]['value'] is 'undefined'
        return null
      else
        return @modules[id]['value']

  # html_id's of descriptors will be stored in modules variable as
  # containers for callbacks.
  modules: {}

  init : (id) ->
    ###
    Initialize objects per id.
    Id is html_id of descriptor.
    ###
    @modules[id] = @modules[id] or {}
    @modules[id].tabSwitch = @modules[id]['tabSwitch'] or {}
    @modules[id].modelUpdate = @modules[id]['modelUpdate'] or {}


class @TabsEditingDescriptor
  @isInactiveClass : "is-inactive"

  constructor: (element) ->
    @element = element;
    ###
    Does not tested on syncing of multiple editors of same type in tabs
    (Like many CodeMirrors)
    ###

    # hide editor/settings bar
    $('.component-edit-header').hide()

    @$tabs = $(".tab", @element)
    @$content = $(".component-tab", @element)

    @element.find('.editor-tabs .tab').each (index, value) =>
      $(value).on('click', @onSwitchEditor)

    # If default visible tab is not setted or if were marked as current
    # more than 1 tab just first tab will be shown
    currentTab = @$tabs.filter('.current')
    currentTab = @$tabs.first() if currentTab.length isnt 1
    @html_id = @$tabs.closest('.wrapper-comp-editor').data('html_id')
    currentTab.trigger("click", [true, @html_id])
    
  onSwitchEditor: (e, firstTime, html_id) =>
    e.preventDefault();

    isInactiveClass = TabsEditingDescriptor.isInactiveClass
    $currentTarget = $(e.currentTarget)

    if not $currentTarget.hasClass('current') or firstTime is true
      previousTab = null

      @$tabs.each( (index, value) ->
        if $(value).hasClass('current')
          previousTab = $(value).html()
      )

      # init and save data from previous tab
      window.TabsEditingDescriptorModel.updateValue(@html_id, previousTab)

      # save data from editor in previous tab to editor in current tab here.

      # call onswitch
      onSwitchFunction = window.TabsEditingDescriptorModel.modules[@html_id].tabSwitch[$currentTarget.text()]
      onSwitchFunction() if $.isFunction(onSwitchFunction)

      @$tabs.removeClass('current')
      $currentTarget.addClass('current')

      # Tabs are implemeted like anchors. Therefore we can use hash to find
      # corresponding content
      content_id = $currentTarget.attr('href')

      @$content
        .addClass(isInactiveClass)
        .filter(content_id)
        .removeClass(isInactiveClass)

  save: ->
    @element.off('click', '.editor-tabs .tab', @onSwitchEditor)
    current_tab = @$tabs.filter('.current').html()
    data: window.TabsEditingDescriptorModel.getValue(@html_id, current_tab)

