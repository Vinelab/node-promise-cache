cache = require('../lib/Cache').create(require('./config'))

describe 'Remembering', ->

    beforeEach -> cache.flush()

    it 'remembers closure result if not found, otherwise it returns the cached value', (done)->

        remember_value = 'remember_val'
        remember = cache.remember 'rem', 22, (done)-> done(remember_value)
        remember.then (result)-> expect(result).toBe('remember_val')
        remember.then -> cache.ttl('rem').then (ttl)->
            expect(ttl).toBe(22)
            cache.get('rem').then (value)-> expect(value).toBe(remember_value); done()


    it 'remembers closure result - forever - if not found, otherwise it returns the cached value', (done)->

        remember_value = 'remember_val_forever'
        remember = cache.remember 'rem', 22, (done)-> done(remember_value)
        remember.then (result)-> expect(result).toBe('remember_val_forever')
        remember.then -> cache.get('rem').then (value)-> expect(value).toBe(remember_value); done()
