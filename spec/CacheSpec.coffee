describe 'Cache', ->

    Q = {
        defer: -> return this
        reject: -> return this
        resolve: -> return this
        promise: {
            then: (callback)-> callback()
        }
    }

    Crypto = {
        createHash: -> return this
        update: -> return this
        digest: -> return this
    }

    Manager = {
        stuff: {}
        set: (key, data, callback)->
            @stuff[key] = data
            callback(null, 'OK')

        setFor: (key, data, ttl, callback)->
            @stuff[key] = data
            @stuff['ttl'] = ttl
            callback(null, 'OK')
        get: (key, callback)-> callback(null, @stuff[key])
        del: (key, callback)-> callback(null, 'OK')
        has: (key, callback)-> callback(null, true)
        ttl: (key, callback)-> callback(null, 19)
        flush: (callback)-> callback(null, 'OK')
        increment: (key, count, callback)-> callback(null, 'OK')
        decrement: (key, count, callback)-> callback(null, 'OK')
    }

    Cache = {}

    beforeEach ->
        spyOn(Q, 'defer').and.callThrough()
        spyOn(Q, 'promise').and.callThrough()
        spyOn(Q, 'resolve').and.callThrough()
        spyOn(Q, 'reject').and.callThrough()

        spyOn(Crypto, 'createHash').and.callThrough()
        spyOn(Crypto, 'update').and.callThrough()
        spyOn(Crypto, 'digest').and.callThrough()

        spyOn(Manager, 'set').and.callThrough()
        spyOn(Manager, 'setFor').and.callThrough()
        spyOn(Manager, 'get').and.callThrough()
        spyOn(Manager, 'del').and.callThrough()
        spyOn(Manager, 'has').and.callThrough()
        spyOn(Manager, 'ttl').and.callThrough()
        spyOn(Manager, 'flush').and.callThrough()
        spyOn(Manager, 'increment').and.callThrough()
        spyOn(Manager, 'decrement').and.callThrough()

        Cache = require('../lib/Cache').instance(Q, Manager, Crypto)

    it 'generates cache store keys with "string" data type keys', ->
        expect(Cache.getCacheKey('something')).toBe("#{Cache.prefix}:something")
        expect(Crypto.createHash).not.toHaveBeenCalled()

    it 'generates cache store key with null prefix', ->
        Cache.prefix = null
        expect(Cache.getCacheKey('somekey')).toBe('somekey')
        expect(Crypto.createHash).not.toHaveBeenCalled()

    it 'generates cache store key with empty prefix', ->
        Cache.prefix = ''
        expect(Cache.getCacheKey('keyss')).toBe('keyss')
        expect(Crypto.createHash).not.toHaveBeenCalled()


    it 'generates cache store keys with "object" key data type using hashing', ->
        key = {id: 1}
        expect(Cache.getCacheKey(key)).not.toBeNull()
        expect(Crypto.createHash).toHaveBeenCalledWith('md5')
        expect(Crypto.update).toHaveBeenCalledWith(JSON.stringify({_key: key}))
        expect(Crypto.digest).toHaveBeenCalledWith('hex')

    it 'generates cache store keys with "array" key data type using hashing', ->
        key = ['some', 'values', 'stacked', 'in', 'a', 'basket', 'of', 'fruits']

        expect(Cache.getCacheKey(key)).not.toBeNull()
        expect(Crypto.createHash).toHaveBeenCalledWith('md5')
        expect(Crypto.update).toHaveBeenCalledWith(JSON.stringify({_key: key}))
        expect(Crypto.digest).toHaveBeenCalledWith('hex')

    it 'maps and stores "string" data in the cache for a specified time defaulting to 1', ->
        data = 'some text here'
        mapped = JSON.stringify({_cached:data})

        expect(Cache.put('key', data)).toBe(Q.promise)

        expect(Q.defer).toHaveBeenCalled()
        expect(Q.resolve).toHaveBeenCalledWith('OK')
        expect(Manager.setFor).toHaveBeenCalledWith(Cache.getCacheKey('key'), mapped, 60, jasmine.any(Function))
        expect(Manager.stuff.ttl).toBe(60)

    it 'maps and stores "string" data in the cache forever', ->
        data = 'some data'
        mapped = JSON.stringify({_cached: data})

        expect(Cache.forever('key', data)).toBe(Q.promise)

        expect(Q.defer).toHaveBeenCalled()
        expect(Q.resolve).toHaveBeenCalledWith('OK')
        expect(Manager.set).toHaveBeenCalledWith(Cache.getCacheKey('key'), mapped, jasmine.any(Function))
        expect(Manager.stuff[Cache.getCacheKey('key')]).toBe mapped

    it 'maps and stores "object" data in the cache for a specified time', ->
        data = {id: 1, name: 'khoza3bal', occupation: 'butt sniffer'}
        mapped = JSON.stringify({_cached:data})

        expect(Cache.put('key', data, 10)).toBe(Q.promise)

        expect(Q.defer).toHaveBeenCalled()
        expect(Q.resolve).toHaveBeenCalledWith('OK')
        expect(Manager.setFor).toHaveBeenCalledWith(Cache.getCacheKey('key'), mapped, 10, jasmine.any(Function))
        expect(Manager.stuff[Cache.getCacheKey('key')]).toBe mapped
        expect(Manager.stuff.ttl).toBe 10

    it 'maps and stores "object" data in the cache forever', ->
        data = {id: 1, name: 'khoza3bal', occupation: 'butt sniffer'}
        mapped = JSON.stringify({_cached:data})

        expect(Cache.forever('key', data)).toBe(Q.promise)

        expect(Q.defer).toHaveBeenCalled()
        expect(Q.resolve).toHaveBeenCalledWith('OK')
        expect(Manager.set).toHaveBeenCalledWith(Cache.getCacheKey('key'), mapped, jasmine.any(Function))
        expect(Manager.stuff[Cache.getCacheKey('key')]).toBe mapped

    it 'maps and stores "array" data in the cache for a specified time', ->
        data = ['take', 'it', 'and', 'go', 'russel']
        mapped = JSON.stringify({_cached:data})

        expect(Cache.put('key', data, 22)).toBe(Q.promise)

        expect(Q.defer).toHaveBeenCalled()
        expect(Q.resolve).toHaveBeenCalledWith('OK')
        expect(Manager.setFor).toHaveBeenCalledWith(Cache.getCacheKey('key'), mapped, 22, jasmine.any(Function))
        expect(Manager.stuff[Cache.getCacheKey('key')]).toBe mapped
        expect(Manager.stuff.ttl).toBe 22

    it 'maps and stores "array" data in the cache forever', ->
        data = ['take', 'it', 'and', 'go', 'russel']
        mapped = JSON.stringify({_cached:data})

        expect(Cache.forever('key', data)).toBe(Q.promise)

        expect(Q.defer).toHaveBeenCalled()
        expect(Q.resolve).toHaveBeenCalledWith('OK')
        expect(Manager.set).toHaveBeenCalledWith(Cache.getCacheKey('key'), mapped, jasmine.any(Function))
        expect(Manager.stuff[Cache.getCacheKey('key')]).toBe mapped

    it 'doesn\'t care about the kind of bad data you give it', ->
        # try null
        data = null
        mapped = JSON.stringify({_cached:data})

        expect(Cache.forever('key', data)).toBe(Q.promise)

        expect(Q.defer).toHaveBeenCalled()
        expect(Q.resolve).toHaveBeenCalledWith('OK')
        expect(Manager.set).toHaveBeenCalledWith(Cache.getCacheKey('key'), mapped, jasmine.any(Function))

        # try undefined
        data = undefined
        mapped = JSON.stringify({_cached:data})

        expect(Cache.forever('key', data)).toBe(Q.promise)

        expect(Q.defer).toHaveBeenCalled()
        expect(Q.resolve).toHaveBeenCalledWith('OK')
        expect(Manager.set).toHaveBeenCalledWith(Cache.getCacheKey('key'), mapped, jasmine.any(Function))

    it 'rejects putting data on error', ->
        error = new Error('something happened')
        # make the manager return an error to the callback on @set
        Manager.setFor = (key, mapped, ttl, callback)-> callback(error)
        expect(Cache.put('key', 'value', 22)).toBe(Q.promise)
        expect(Q.reject).toHaveBeenCalledWith(error)


        Manager.set = (key, mapped, callback)-> callback(error)
        expect(Cache.forever('key', 'value')).toBe(Q.promise)
        expect(Q.reject).toHaveBeenCalledWith(error)

    it 'returns data like a boss, reduced with no garbage and stuff', ->
        Cache.put('key', 'val')

        expect(Cache.get('key')).toBe(Q.promise)
        expect(Q.defer).toHaveBeenCalled()
        expect(Manager.get).toHaveBeenCalledWith(Cache.getCacheKey('key'), jasmine.any(Function))
        expect(Q.resolve).toHaveBeenCalledWith('val')

    it 'rejects getting data on error', ->
        # make the manager return an error to the callback on @get
        Manager.get = (key, callback)-> callback(new Error('something happened'))
        expect(Cache.get('key')).toBe(Q.promise)
        expect(Q.reject).toHaveBeenCalledWith(new Error('something happened'))

    it 'remembers executed code to be returned from cache when available', ->
        Closure = first: (done)-> done('data')

        spyOn(Closure, 'first').and.callThrough()
        spyOn(Cache, 'get').and.callThrough()
        spyOn(Cache, 'has').and.callThrough()
        spyOn(Cache, 'put').and.callThrough()
        spyOn(Q.promise, 'then').and.callThrough()

        Cache.remember('key', 10, Closure.first)

        expect(Q.defer).toHaveBeenCalled()
        expect(Cache.has).toHaveBeenCalledWith('key')
        expect(Q.promise.then).toHaveBeenCalledWith(jasmine.any(Function))
        expect(Closure.first).toHaveBeenCalled()
        expect(Cache.put).toHaveBeenCalledWith('key', 'data', 10)
        expect(Q.resolve).toHaveBeenCalledWith('data')

    it 'returns remembered closure result', ->
        Closure = found: (done)-> done('data')
        spyOn(Closure, 'found').and.callThrough()
        spyOn(Q.promise, 'then').and.returnValue(true)
        expect(Cache.remember('key', 10, Closure.found)).toBe(Q.promise)
        expect(Closure.found).not.toHaveBeenCalled()
        expect(Q.resolve).toHaveBeenCalledWith(yes)

    it 'remembers - forever - executed code to be returned from cache when available', ->
        Closure = first: (done)-> done('data')

        spyOn(Closure, 'first').and.callThrough()
        spyOn(Cache, 'get').and.callThrough()
        spyOn(Cache, 'has').and.callThrough()
        spyOn(Cache, 'forever').and.callThrough()
        spyOn(Q.promise, 'then').and.callThrough()

        Cache.rememberForever('key', Closure.first)

        expect(Q.defer).toHaveBeenCalled()
        expect(Cache.has).toHaveBeenCalledWith('key')
        expect(Q.promise.then).toHaveBeenCalledWith(jasmine.any(Function))
        expect(Closure.first).toHaveBeenCalled()
        expect(Cache.forever).toHaveBeenCalledWith('key', 'data')
        expect(Q.resolve).toHaveBeenCalledWith('data')

    it 'returns - forever - remembered closure result', ->

        Closure = found: -> 'data'
        spyOn(Closure, 'found').and.callThrough()
        spyOn(Q.promise, 'then').and.returnValue(true)
        expect(Cache.remember('key', Closure.found)).toBe(Q.promise)
        expect(Closure.found).not.toHaveBeenCalled()
        expect(Q.resolve).toHaveBeenCalledWith(yes)

    it 'increments an item value by the given count or defaults to 1', ->
        expect(Cache.increment('key')).toBe(Q.promise)
        expect(Manager.increment).toHaveBeenCalledWith(Cache.getCacheKey('key'), 1, jasmine.any(Function))

        expect(Cache.increment('key', 22)).toBe(Q.promise)
        expect(Manager.increment).toHaveBeenCalledWith(Cache.getCacheKey('key'), 22, jasmine.any(Function))

     it 'decrements an item value by the given count or defaults to 1', ->
        expect(Cache.decrement('key')).toBe(Q.promise)
        expect(Manager.decrement).toHaveBeenCalledWith(Cache.getCacheKey('key'), 1, jasmine.any(Function))

        expect(Cache.decrement('key', 32)).toBe(Q.promise)
        expect(Manager.decrement).toHaveBeenCalledWith(Cache.getCacheKey('key'), 32, jasmine.any(Function))


    it 'checks whether the cache has a given item by key', ->
        expect(Cache.has('key')).toBe(Q.promise)
        expect(Manager.has).toHaveBeenCalledWith(Cache.getCacheKey('key'), jasmine.any(Function))

    it 'returns the TTL of a given key', ->
        expect(Cache.ttl('key')).toBe(Q.promise)
        expect(Manager.ttl).toHaveBeenCalledWith(Cache.getCacheKey('key'), jasmine.any(Function))

    it 'flushes the cache', ->
        expect(Cache.flush()).toBe(Q.promise)
        expect(Manager.flush).toHaveBeenCalled()

    it 'forgets about an item in cache', ->
        expect(Cache.forget('key')).toBe(Q.promise)
        expect(Manager.del).toHaveBeenCalledWith(Cache.getCacheKey('key'), jasmine.any(Function))
        expect(Q.resolve).toHaveBeenCalledWith('OK')

    it 'rejects forgetting an item on error', ->
        Manager.del = (key, callback)-> callback(new Error('something happened'))

        expect(Cache.forget('key')).toBe(Q.promise)
        expect(Q.reject).toHaveBeenCalledWith(new Error('something happened'))

