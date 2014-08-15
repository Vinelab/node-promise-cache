q = require 'q'
cache = require('../lib/Cache').create(require('./config'))

describe 'Incrementing', ->

    beforeEach -> cache.flush()

    it 'increments item with given value or defaults to incrementing by 1', (done)->
        inc = cache.increment('count', 10)
        inc.then (result)->
            expect(result).toBe(10)
            cache.get('count').then (count)->
                expect(count).toBe(10)
                cache.increment('count').then ->
                    cache.get('count').then (count)->
                        expect(count).toBe(11)
                        done()

describe 'Decrementing', ->

    beforeEach -> cache.flush()

    it 'decrements item with given value or defaults to decrementing by 1', (done)->
        dec = cache.decrement('dcount', 20)
        dec.then (result)->
            expect(result).toBe(-20)
            cache.get('dcount').then (count)->
                expect(count).toBe(-20)
                cache.decrement('dcount').then ->
                    cache.get('dcount').then (count)->
                        expect(count).toBe(-21)
                        done()
