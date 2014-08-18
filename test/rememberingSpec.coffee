cache = require('../lib/Cache').create(require('./config'))

describe 'Remembering', ->

    beforeEach -> cache.flush()

    it 'remembers closure result if not found, otherwise it returns the cached value', (done)->

        remember_value = 'remember_val'

        remember = cache.remember('rem', 22, -> remember_value).then (result)-> expect(result).toBe('remember_val')
        remember.then -> cache.ttl('rem').then (ttl)->
            expect(ttl).toBe(22)
            done()
