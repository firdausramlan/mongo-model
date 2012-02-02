should  = require 'should'
require '../helper'
mongo = require '../../lib/driver'

describe "Driver Db", ->
  withMongo()

  itSync "should provide handy shortcuts to collections", ->
    $db.collection('test').name.should.eql 'test'

  itSync "should list collection names", ->
    $db.collection('alpha').create a: 'b'
    $db.collectionNames()
    $db.collectionNames().should.include 'alpha'

  itSync "should clear database", ->
    $db.collection('alpha').insert a: 'b'
    $db.collectionNames().should.include 'alpha'
    $db.clear()
    $db.collectionNames().should.not.include 'alpha'

describe "Driver Collection", ->
  withMongo()

  describe "CRUD", ->
    itSync "should create", ->
      units = $db.collection 'units'
      unit = name: 'Probe',  status: 'alive'
      _(units.create(unit)).should.exist
      _(unit._id).should.exist
      units.first(name: 'Probe').status.should.eql 'alive'

    itSync "should update", ->
      units = $db.collection 'units'
      unit = name: 'Probe',  status: 'alive'
      units.create unit
      units.first(name: 'Probe').status.should.eql 'alive'
      unit.status = 'dead'
      units.update {_id: unit._id}, unit
      units.first(name: 'Probe').status.should.eql 'dead'
      units.count().should.eql 1

    itSync "should update in-place", ->
      units = $db.collection 'units'
      units.create name: 'Probe',  status: 'alive'
      units.update({name: 'Probe'}, $set: {status: 'dead'}).should.eql 1
      units.first(name: 'Probe').status.should.eql 'dead'

    itSync "should delete", ->
      units = $db.collection 'units'
      units.create name: 'Probe',  status: 'alive'
      units.delete(name: 'Probe').should.eql 1
      units.count(name: 'Probe').should.eql 0

    itSync "should update all matched by criteria (not just first as default in mongo)", ->
      units = $db.collection 'units'
      units.save name: 'Probe',  race: 'Protoss', status: 'alive'
      units.save name: 'Zealot', race: 'Protoss', status: 'alive'
      units.update {race: 'Protoss'}, $set: {status: 'dead'}
      units.all().map((u) -> u.status).should.eql ['dead', 'dead']
      units.delete race: 'Protoss'
      units.count().should.eql 0

    itSync "should use autogenerated random string id (if specified, instead of default BSON::ObjectId)", ->
      units = $db.collection 'units'
      unit = name: 'Probe',  status: 'alive'
      units.create unit
      _.isString(unit._id).should.be.true

  describe "Querying", ->
    itSync "should return first element", ->
      units = $db.collection 'units'
      _(units.first()).should.not.exist
      units.save name: 'Zeratul'
      units.first(name: 'Zeratul').name.should.eql 'Zeratul'

    itSync 'should return all elements', ->
      units = $db.collection 'units'
      units.all().should.eql []
      units.save name: 'Zeratul'
      list = units.all(name: 'Zeratul')
      list.length.should.eql 1
      list[0].name.should.eql 'Zeratul'

    itSync 'should return count of elements', ->
      units = $db.collection 'units'
      units.count(name: 'Zeratul').should.eql 0
      units.save name: 'Zeratul'
      units.save name: 'Tassadar'
      units.count(name: 'Zeratul').should.eql 1

    itSync "should delete via cursor", ->
      units = $db.collection 'units'
      units.create name: 'Probe',  status: 'alive'
      units.find(name: 'Probe').delete()
      units.count(name: 'Probe').should.eql 0

describe "Driver Configuration", ->
  withMongo()

  oldOptions = null
  beforeEach -> oldOptions = _(mongo.options).clone()
  afterEach  -> mongo.options = oldOptions

  itSync "should use config and get database by its alias", ->
    config =
      databases:
        mytest:
          name: 'test'
    mongo.configure config

    try
      db = mongo._db('mytest')
      db.name.should.eql 'test'
    finally
      db.close() if db