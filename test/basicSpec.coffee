q = require 'q'
cache = require('../lib/Cache').create(require('./config'))

describe 'Basic:', ->

    beforeEach -> cache.flush()

    it 'storing forever and forgetting', (done)->

        value = 'val'
        # Store key -> val
        stored = cache.forever('key', value).then (result)->
            expect(result).toBe('OK')

            ## Validate existence.
            cache.has('key').then (exists)->
                expect(exists).toBe(true)
                ## Get the key
                cache.get('key').then (fetched)->
                    expect(fetched).toBe(value)

                    ## Delete
                    cache.forget('key').then (forgotten)->
                        expect(forgotten).toBe(true)
                        cache.get('key').then (again)->
                            expect(again).toBe(null)
                            done()
