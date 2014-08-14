describe 'Cache', ->

    Q = {
        defer: -> return this
        reject: -> return this
        resolve: -> return this
        promise: -> return P
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
        expect(Manager.setFor).toHaveBeenCalledWith(Cache.getCacheKey('key'), mapped, 1, jasmine.any(Function))
        expect(Manager.stuff.ttl).toBe 1

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

    it 'remembers executed code to be returned from cache when available, otherwise hold the promise and store the result', ->
        # execute first time assuming no data is stored (Q.promise.then returns null)
        Q.promise = {then: (callback)-> callback(null)}
        spyOn(Q.promise, 'then').and.callThrough()

        p = {then: (callback)-> callback('data')}
        spyOn(p, 'then').and.callThrough()

        spyOn(Cache, 'get').and.callThrough()
        spyOn(Cache, 'put').and.callThrough()

        Cache.remember('key', 10, p)

        expect(Q.defer).toHaveBeenCalled()
        expect(Cache.get).toHaveBeenCalledWith('key')
        expect(Q.promise.then).toHaveBeenCalledWith(jasmine.any(Function))
        expect(p.then).toHaveBeenCalledWith(jasmine.any(Function))
        expect(Cache.put).toHaveBeenCalledWith('key', 'data', 10)
        expect(Q.resolve).toHaveBeenCalledWith('data')

        # now we assume the data have been stored so remember should
        # return the data from cache
        Q.promise = {then: (callback)-> callback('stored-data')}
        p_found = {then: ->}

        spyOn(p_found, 'then')

        expect(Cache.remember('key', p_found)).toBe(Q.promise)
        expect(p_found.then).not.toHaveBeenCalled()
        expect(Q.resolve).toHaveBeenCalledWith('stored-data')

    it 'forever remembers executed code to be returned from cache when available, otherwise hold the promise and store the results', ->
        # execute first time assuming no data is stored (Q.promise.then returns null)
        Q.promise = {then: (callback)-> callback(null)}
        spyOn(Q.promise, 'then').and.callThrough()

        p = {then: (callback)-> callback('data')}
        spyOn(p, 'then').and.callThrough()

        spyOn(Cache, 'get').and.callThrough()
        spyOn(Cache, 'forever').and.callThrough()

        Cache.rememberForever('key', p)

        expect(Q.defer).toHaveBeenCalled()
        expect(Cache.get).toHaveBeenCalledWith('key')
        expect(Q.promise.then).toHaveBeenCalledWith(jasmine.any(Function))
        expect(p.then).toHaveBeenCalledWith(jasmine.any(Function))
        expect(Cache.forever).toHaveBeenCalledWith('key', 'data')
        expect(Q.resolve).toHaveBeenCalledWith('data')

        # now we assume the data have been stored so remember should
        # return the data from cache
        Q.promise = {then: (callback)-> callback('stored-data')}
        p_found = {then: ->}

        spyOn(p_found, 'then')

        expect(Cache.remember('key', p_found)).toBe(Q.promise)
        expect(p_found.then).not.toHaveBeenCalled()
        expect(Q.resolve).toHaveBeenCalledWith('stored-data')

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

