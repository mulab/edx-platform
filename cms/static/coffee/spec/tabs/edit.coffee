describe "TabsEditingDescriptor", ->
  beforeEach ->
    @isInactiveClass = "is-inactive"
    @isCurrent = "current"
    loadFixtures 'tabs-edit.html'
    @descriptor = new TabsEditingDescriptor($('.base_wrapper'))
    @html_id = 'test_id'
    @tab_0_switch = jasmine.createSpy('tab_0_switch');
    @tab_0_save = jasmine.createSpy('tab_0_save');
    @tab_1_switch = jasmine.createSpy('tab_1_switch');
    @tab_1_save = jasmine.createSpy('tab_1_save');
    TabsEditingDescriptorModel.addSave(@html_id, 'Tab 0 Editor', @tab_0_save)
    TabsEditingDescriptorModel.addOnSwitch(@html_id, 'Tab 0 Editor', @tab_0_switch)
    TabsEditingDescriptorModel.addSave(@html_id, 'Tab 1 Transcripts', @tab_1_save)
    TabsEditingDescriptorModel.addOnSwitch(@html_id, 'Tab 1 Transcripts', @tab_1_switch)

    spyOn($.fn, 'hide').andCallThrough()
    spyOn($.fn, 'show').andCallThrough()
    spyOn(TabsEditingDescriptorModel, 'init')
    spyOn(TabsEditingDescriptorModel, 'updateValue')

  afterEach ->
    TabsEditingDescriptorModel.modules= {}

  describe "constructor", ->
    it "first tab should be visible", ->
      expect(@descriptor.$tabs.first()).toHaveClass(@isCurrent)
      expect(@descriptor.$content.first()).not.toHaveClass(@isInactiveClass)

  describe "onSwitchEditor", ->
    it "switching tabs changes styles", ->
      @descriptor.$tabs.eq(1).trigger("click")
      expect(@descriptor.$tabs.eq(0)).not.toHaveClass(@isCurrent)
      expect(@descriptor.$content.eq(0)).toHaveClass(@isInactiveClass)
      expect(@descriptor.$tabs.eq(1)).toHaveClass(@isCurrent)
      expect(@descriptor.$content.eq(1)).not.toHaveClass(@isInactiveClass)
      expect(@tab_1_switch).toHaveBeenCalled()

    it "if click on current tab, anything should happens", ->
      spyOn($.fn, 'trigger').andCallThrough()
      currentTab = @descriptor.$tabs.filter('.' + @isCurrent)
      @descriptor.$tabs.eq(0).trigger("click")
      expect(@descriptor.$tabs.filter('.' + @isCurrent)).toEqual(currentTab)
      expect($.fn.trigger.calls.length).toEqual(1)

    it "onSwitch function call", ->
      @descriptor.$tabs.eq(1).trigger("click")
      expect(TabsEditingDescriptorModel.updateValue).toHaveBeenCalled()
      expect(@tab_1_switch).toHaveBeenCalled()

  describe "save", ->
    it "function for current tab should be called", ->
      @descriptor.$tabs.eq(1).trigger("click")
      data = @descriptor.save().data
      expect(@tab_1_save).toHaveBeenCalled()

    it "detach click event", ->
      spyOn($.fn, "off")
      @descriptor.save()
      expect($.fn.off).toHaveBeenCalledWith(
        'click',
        '.editor-tabs .tab',
        @descriptor.onSwitchEditor
      )

  describe "editor/settings header", ->
    it "is hidden", ->
      expect(@descriptor.element.find(".component-edit-header").css('display')).toEqual('none')

describe "TabsEditingDescriptor special save cases", ->
  beforeEach ->
    @isInactiveClass = "is-inactive"
    @isCurrent = "current"
    loadFixtures 'tabs-edit.html'
    @descriptor = new window.TabsEditingDescriptor($('.base_wrapper'))
    @html_id = 'test_id'

  describe "save", ->
    it "case: no init", ->
      data = @descriptor.save().data
      expect(data).toEqual(null)

    it "case: no function in model update", ->
      TabsEditingDescriptorModel.init(@html_id)
      data = @descriptor.save().data
      expect(data).toEqual(null)

    it "case: no function in model update, but value presented", ->
      @tab_0_save = jasmine.createSpy('tab_0_save').andReturn(1)
      TabsEditingDescriptorModel.addSave(@html_id, 'Tab 0 Editor', @tab_0_save)
      @descriptor.$tabs.eq(1).trigger("click")
      expect(@tab_0_save).toHaveBeenCalled()
      data = @descriptor.save().data
      expect(data).toEqual(1)

