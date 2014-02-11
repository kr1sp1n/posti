#
# posti 
#
# options: 
#   -u USER
#   -p PASSWORD
#   -h HOST
#   -P PORT (993)
#   -b BOX ('INBOX')
#   --width WIDTH in chars
#

charm = require('charm')()
Table = require 'cli-table'
moment = require 'moment'
_ = require 'underscore'
argv = require('minimist')(process.argv.slice(2))
EventEmitter = require('events').EventEmitter
Imap = require 'imap'

charm.pipe process.stdout
charm.cursor false
charm.reset()

getTable = (width)->
  c = width/10
  table = new Table
    head: ['FROM', 'SUBJECT', 'WHEN']
    colWidths: [c*2, c*6, c*2]
    style:
      'padding-left': 0
      'padding-right': 0
      'head': ['cyan']
      'compact': true
    chars:
      'top': ''
      'top-mid': ''
      'top-left': ''
      'top-right': ''
      'bottom': ''
      'bottom-mid': ''
      'bottom-left': ''
      'bottom-right': ''
      'left': ''
      'left-mid': ''
      'mid': ''
      'mid-mid': ''
      'right': ''
      'right-mid': ''
      'middle': ' '

  return table


class Mailbox extends EventEmitter
  constructor: (@opts = {})->
    @opts.name ?= 'INBOX'
    @opts.port?= 993 
    @opts.tls?= true 

    @connection = new Imap
      user: @opts.user 
      password: @opts.password 
      host: @opts.host 
      port: @opts.port 
      tls: @opts.tls 
      tlsOptions:
        rejectUnauthorized: false
    
    @connection.once 'ready', =>
      #@connection.getBoxes (err, b)->
      #  console.log b
      #  console.log err 
      @open()
      
    @connection.on 'error', (err)->
      console.log err

  connect: ->
    @connection.connect()

  open: ->
    @connection.openBox @opts.name, true, (err, box)=>
      @info = box
      @emit 'open', err, @info

  check: ->
    unless @connection.state == 'disconnected'
      @connection.search ['UNSEEN'], (err, uids)=>
        console.error err if err
        if uids.length > 0
          @emit 'unseen', uids

  fetch: (uids)->
    f = @connection.fetch uids, 
      bodies: 'HEADER.FIELDS (FROM SUBJECT DATE)'
      struct: true

    f.on 'error', (err)->
      console.error err

    f.on 'message', (msg, seqno)=>
      attributes = null
      bodyStream = null
      
      msg.on 'attributes', (attr)->
        attributes = attr

      msg.on 'body', (stream, info)->
        bodyStream = stream

      msg.on 'end', =>
        buffer = ''
        bodyStream.on 'data', (chunk)->
          buffer += chunk.toString('utf8')
        
        bodyStream.once 'end', =>
          item = Imap.parseHeader buffer
          item.attributes = attributes
          @emit 'message', item
   
      
  parseInput: (buf)=>
    codes = [].join.call(buf, '.')

    if isExit(codes)
      @emit 'exit'

    #if isEnter(codes)
    #  @emit 'select', @selectedRow


###
    if isUp(codes) and @selectedRow > 1
      @selectedRow = @selectedRow - 1

    if isDown(codes) and @selectedRow < mailBoxes['INBOX'].table.length
      @selectedRow = @selectedRow + 1
###
    

options = {}
options.user = argv.u
options.password = argv.p
options.host = argv.h
options.port= argv.P
options.name= argv.b

width = argv.width or 80

m = new Mailbox options
unseen = [] # uids
messages = []

m.on 'open', (err, box)->
  m.check()
  charm
    .position(0, 0)
    .write(box.name)

m.on 'select', (selectedRow)->
  #console.log selectedRow

m.on 'unseen', (uids)->
  diff = _.difference uids, unseen 
  unseen = _.union unseen, uids
  if diff.length > 0
    m.fetch diff  

m.on 'exit', ->
  process.stdin.setRawMode false
  charm.cursor true
  charm.reset()
  process.exit()

m.on 'message', (m)->
  messages.push m
  render()
  

m.connect()

render = ->
  t = getTable width
  messages = _(messages).sortBy((m) -> new Date(m.date[0]))
  messages.forEach (m)->
    date = moment(new Date(m.date[0])).fromNow()
    re = /"/gi
    from = m.from[0].split('<')[0].replace(re, '')
    t.push [from, m.subject[0], date]

  charm
    .position(0, 3)
    .write(t.toString())


cycle = setInterval ->
  m.check()
, 5000


process.stdin.on 'data', m.parseInput
process.stdin.setRawMode true
process.stdin.resume()


charm.on '^C', ->
  charm.cursor true
  process.exit

# HANDLE KEYBOARD INPUT
isExit = (codes)->
  return codes == '3' or codes == '113' # ^C or q

isUp = (codes)->
  return codes == '27.91.65' or codes == '107' # up or k

isDown = (codes)->
  return codes == '27.91.66' or codes == '106' # down up or j

isEnter= (codes)->
  return codes == '13' # enter


writeList = (x, y, list, selected = 1)->
  rows = list.toString().split('\n')
  line = y 
  for row, index in rows
    charm.position(x, line++)
    if index == selected
      #charm.display 'blink'
      charm.display 'underscore'
    else
      charm.display 'reset'

    charm.write row

# exports as app
module.exports =
  run: ->

