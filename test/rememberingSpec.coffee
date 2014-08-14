q = require 'q'
cache = require('../lib/Cache').create()

describe 'Remembering', ->

    beforeEach -> cache.flush()

    it 'remembers resolved promise result if not found, otherwise it returns the cached value', (done)->

        remember_value = 'remember_val'

        q = require 'q'
        remdfd = q.defer()

        remember = cache.remember('rem', 22, remdfd.promise).then (result)-> expect(result).toBe('remember_val')
        remdfd.resolve(remember_value)

        remember.then -> cache.ttl('rem').then (ttl)->
            expect(ttl).toBe(22)
            done()
