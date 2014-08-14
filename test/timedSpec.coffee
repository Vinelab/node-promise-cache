q = require 'q'
cache = require('../lib/Cache').create()

describe 'Times', ->

    beforeEach -> cache.flush()

    it 'stores a value for a spcified time', (done)->

        timed_value = 'timed_value'
        timed = cache.put('timed_key', timed_value, 10).then (result)->
            expect(result).toBe('OK')

            cache.ttl('timed_key').then (ttl)->
                expect(ttl).toBe(10)
                done()
