class @VideoPlayer extends Subview
  initialize: ->
    # Define a missing constant of Youtube API
    YT.PlayerState.UNSTARTED = -1

    @currentTime = 0
    @el = $("#video_#{@video.id}")

  bind: ->
    _this = this

    $(@control).bind('play', @play)
      .bind('pause', @pause)
    $(@qualityControl).bind('changeQuality', @handlePlaybackQualityChange)
    $(@caption).bind('seek', @onSeek)
    $(@speedControl).bind('speedChange', @onSpeedChange)
    $(@progressSlider).bind('seek', @onSeek)
    if @volumeControl
      $(@volumeControl).bind('volumeChange', @onVolumeChange)
    $(document).keyup @bindExitFullScreen

    # If captions are enabled, attach a mouse leave event to the captions DIV.
    # It will check whether the captions were opened by a mouse enter event,
    # and hide them if this is so.
    if @video.show_captions is true
      @el.find(".subtitles").mouseleave (event) ->
        unless event.offsetX
          event.offsetX = (event.pageX - $(event.target).offset().left)
          event.offsetY = (event.pageY - $(event.target).offset().top)

        if (_this.caption.disableMouseLeave is false) and (_this.caption.el.hasClass("closed") is false)
          _this.caption.captionsOpenWithMouse = false
          _this.caption.hideCaptions true

    @$('.add-fullscreen').click @toggleFullScreen
    @addToolTip() unless onTouchBasedDevice()

  bindExitFullScreen: (event) =>
    if @el.hasClass('fullscreen') && event.keyCode == 27
      @toggleFullScreen(event)

  render: ->
    @control = new VideoControl el: @$('.video-controls')
    @qualityControl = new VideoQualityControl el: @$('.secondary-controls')

    # If captions are enabled, we will show a horizontal bar with arrow at the
    # right side. Also, we will create an area there which will trigger the
    # display of captions when the mouse hovers over it. When the captions are
    # shown, the vertical bar will be hidden automatically.
    if @video.show_captions is true
      @captionVertBar = new VideoCaptionVertBar el: @el, videoPlayer: this

    @caption = new VideoCaption
        el: @el
        youtubeId: @video.youtubeId('1.0')
        currentSpeed: @currentSpeed()
        captionDataDir: @video.caption_data_dir
    unless onTouchBasedDevice()
      @volumeControl = new VideoVolumeControl el: @$('.secondary-controls')
    @speedControl = new VideoSpeedControl el: @$('.secondary-controls'), speeds: @video.speeds, currentSpeed: @currentSpeed()
    @progressSlider = new VideoProgressSlider el: @$('.slider')
    @playerVars =
      controls: 0
      wmode: 'transparent'
      rel: 0
      showinfo: 0
      enablejsapi: 1
      modestbranding: 1
    if @video.start
      @playerVars.start = @video.start
    if @video.end
      # work in AS3, not HMLT5. but iframe use AS3
      @playerVars.end = @video.end

    @player = new YT.Player @video.id,
      playerVars: @playerVars
      videoId: @video.youtubeId()
      events:
        onReady: @onReady
        onStateChange: @onStateChange
        onPlaybackQualityChange: @onPlaybackQualityChange
    @caption.hideCaptions(@['video'].hide_captions)

    # If the user disabled captions in the XML, lets hide them.
    if @video.show_captions is false
      @el.find('.hide-subtitles').remove();

  addToolTip: ->
    @$('.add-fullscreen, .hide-subtitles').qtip
      position:
        my: 'top right'
        at: 'top center'

  onReady: (event) =>
    unless onTouchBasedDevice()
      $('.video-load-complete:first').data('video').player.play()

  onStateChange: (event) =>
    switch event.data
      when YT.PlayerState.UNSTARTED
        @onUnstarted()
      when YT.PlayerState.PLAYING
        @onPlay()
      when YT.PlayerState.PAUSED
        @onPause()
      when YT.PlayerState.ENDED
        @onEnded()

  onPlaybackQualityChange: (event, value) =>
    quality = @player.getPlaybackQuality()
    @qualityControl.onQualityChange(quality)

  handlePlaybackQualityChange: (event, value) =>
    @player.setPlaybackQuality(value)

  onUnstarted: =>
    @control.pause()
    @caption.pause()

  onPlay: =>
    @video.log 'play_video'
    window.player.pauseVideo() if window.player && window.player != @player
    window.player = @player
    unless @player.interval
      @player.interval = setInterval(@update, 200)
    @caption.play()
    @control.play()
    @progressSlider.play()

  onPause: =>
    @video.log 'pause_video'
    window.player = null if window.player == @player
    clearInterval(@player.interval)
    @player.interval = null
    @caption.pause()
    @control.pause()

  onEnded: =>
    @control.pause()
    @caption.pause()

  onSeek: (event, time) =>
    @player.seekTo(time, true)
    if @isPlaying()
      clearInterval(@player.interval)
      @player.interval = setInterval(@update, 200)
    else
      @currentTime = time
    @updatePlayTime time

  onSpeedChange: (event, newSpeed) =>
    @currentTime = Time.convert(@currentTime, parseFloat(@currentSpeed()), newSpeed)
    newSpeed = parseFloat(newSpeed).toFixed(2).replace /\.00$/, '.0'
    @video.setSpeed(newSpeed)
    @caption.currentSpeed = newSpeed

    if @isPlaying()
      @player.loadVideoById(@video.youtubeId(), @currentTime)
    else
      @player.cueVideoById(@video.youtubeId(), @currentTime)
    @updatePlayTime @currentTime

  onVolumeChange: (event, volume) =>
    @player.setVolume volume

  update: =>
    if @currentTime = @player.getCurrentTime()
      @updatePlayTime @currentTime

  updatePlayTime: (time) ->
    progress = Time.format(time) + ' / ' + Time.format(@duration())
    @$(".vidtime").html(progress)
    @caption.updatePlayTime(time)
    @progressSlider.updatePlayTime(time, @duration())

  toggleFullScreen: (event) =>
    event.preventDefault()
    if @el.hasClass('fullscreen')
      @$('.add-fullscreen').attr('title', 'Fill browser')
      @el.removeClass('fullscreen')
    else
      @el.addClass('fullscreen')
      @$('.add-fullscreen').attr('title', 'Exit fill browser')
    @caption.resize()

  # Delegates
  play: =>
    @player.playVideo() if @player.playVideo

  isPlaying: ->
    @player.getPlayerState() == YT.PlayerState.PLAYING

  pause: =>
    @player.pauseVideo() if @player.pauseVideo

  duration: ->
    @video.getDuration()

  currentSpeed: ->
    @video.speed

  volume: (value) ->
    if value?
      @player.setVolume value
    else
      @player.getVolume()
