Crafty.scene 'game', ->
  Crafty.background('white')

  # initialization

  ui =
    backgroundEls:  Crafty.e('BackgroundElements')

    feedbackLabel:  Crafty.e('Notification').attr(x: 160, y: 250, w: 260, h: 40)

    customerCash:   Crafty.e('CashPile').attr(x: 20, y: 115).dir('down')
    cashOut:        Crafty.e('CashPile').attr(x: 20, y: 400).dir('up')

    cashRegister:   Crafty.e('2D, DOM, Image').image(Game.images.cashRegister).attr(x: 560, y: 50, z: 500)
    cashTray:       Crafty.e('CashTray')
    receipt:        Crafty.e('Receipt')
    ticker:         Crafty.e('Ticker')
    score:          Crafty.e('Score').attr(x: 574, y: 7)
    combo:          Crafty.e('Combo').attr(x: 559, y: 24)

    soundControls:  Crafty.e('SoundControls').attr(x: 895, y: 14).soundtrack(Game.soundtrack)
    foregroundEls:  Crafty.e('ForegroundElements')

  window.ui = ui
  currentCustomer = null
  player = new Game.Player()
  score = new Game.Score(ticker:ui.ticker)
  undoStack = []

  # event bindings

  moveFromTrayToOut = (denomination, skipUndo = false) ->
    player.get('cashInRegister').subtract(denomination)
    player.get('cashOut').add(denomination)
    undoStack.push(denomination) unless skipUndo
    Game.sfx.playDenomination(denomination)

  moveBackToTray = (denomination, skipUndo = false) ->
    player.get('cashOut').subtract(denomination)
    player.get('cashInRegister').add(denomination)
    undoStack.push(-1 * denomination) unless skipUndo
    Game.sfx.playDenomination(denomination)

  undo = ->
    top = undoStack.pop()
    if (top)
      denomination = Math.abs(top)
      if (top > 0) then moveBackToTray(denomination, true) else moveFromTrayToOut(denomination, true)

  ui.cashTray.bind 'DenominationClick', moveFromTrayToOut
  ui.cashOut.bind 'DenominationClick', moveBackToTray

  ui.cashTray.bind 'Refill', (denomination) ->
    ui.ticker.subtractTime(2)
    player.get('cashInRegister').add(denomination, 10)

  @bind 'KeyDown', (ev) ->
    if ev.key == Config.input.undo or ev.key == Config.input.alt_undo
      ev.originalEvent.preventDefault()
      ev.originalEvent.stopPropagation()
      undo()
    else if (ev.key == Config.input.submit) or (ev.key == Config.input.otherSubmit)
      submitRound()
    else
      _.each Game.DENOMINATIONS, (d)->
        if ev.key == Config.input.money[d] or ev.key == Config.input.alt_money[d]
          if ev.shiftKey
            moveBackToTray(d)
          else
            moveFromTrayToOut(d)

  ui.cashTray.bind('Submit', -> submitRound())

  # methods

  submitRound = ->
    difference = Math.abs(currentCustomer.correctChange() - player.get('cashOut').value())
    text = "GREAT!"
    if difference > 0
      text = "You were off by #{difference.toMoneyString()}"
      ui.feedbackLabel.showNegative(text)
    else
      ui.feedbackLabel.showPositive("GREAT!")
    score.submit(difference)

    player.get('cashInRegister').merge(currentCustomer.get('paid'))
    player.set('cashOut', new Game.Cash())
    generateNewRound()
    Game.sfx.playRegisterOpen()

  generateNewRound = ->
    currentCustomer = new Game.Customer()
    ui.receipt.customer(currentCustomer).animateUp()

    ui.cashTray.open()
    ui.customerCash.cash(currentCustomer.get('paid'))
    ui.cashOut.cash(player.get('cashOut'))
    undoStack = []


  endGame = ->
    Crafty.e('Receipt').attr(x:300, y:40, w: 360, h:600, z:2000).yPos(40).heightForAnimation(600).animateUp()
#    alert("Time Ended! Your score:#{score.get('points')}") # temporary
#    Crafty.scene('menu')

  # run
  ui.score.scoreModel(score)
  ui.combo.scoreModel(score)
  ui.cashTray.cash(player.get('cashInRegister'))
  ui.ticker.bind('RoundTimeEnded', endGame)
  generateNewRound()