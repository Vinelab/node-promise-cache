class Cache

    ###
    # Create a new Cache instance.
    #
    # @param {object} Q The promise manager.
    # @param {object} Manager The cache store manager. (check /lib/stores)
    # @param {object} Crypto node's crypto module
    # @return Cache
    ###
    constructor: (@Q, @Manager, @Crypto, config)->
        @prefix = if config? and config?.prefix? then config.prefix else 'pcache'
        @default_ttl = if config? and config?.ttl? then config.ttl else 60

    ###*
     # Get the cache key.
     #
     # @param {mixed} key
     # @return string
    ###
    getCacheKey: (key)=>
        if not @prefix or @prefix.length <= 0
            return key
        else
            return "#{@prefix}:#{key}" if typeof key is 'string'

            hash = @Crypto.createHash('md5').update(JSON.stringify({_key: key})).digest('hex')
            return "#{@prefix}:#{hash}"

    ###
    # Store an item in the cache for a given number of seconds.
    #
    # @param {mixed} key
    # @param {mixed} value
    # @param {int} ttl
    # @return {Q.promise} Deferred Promise.
    ###
    put: (key, value, ttl = @default_ttl)->
        dfd = @Q.defer()

        key = @getCacheKey(key)
        # map data to be cached
        mapped = JSON.stringify({_cached: value})

        @Manager.setFor key, mapped, ttl, (err, result)->
            return dfd.reject(err) if err
            dfd.resolve(result)

        return dfd.promise

    ###
    # Store an item in the cache indefinitely.
    #
    # @param {mixed} key
    # @param {mixed} value
    # @return {Q.promise}
    ###
    forever: (key, value)->
        dfd = @Q.defer()

        key = @getCacheKey(key)
        # map data to be cached
        mapped = JSON.stringify({_cached: value})

        @Manager.set key, mapped, (err, result)->
            return dfd.reject(err) if err
            dfd.resolve(result)

        return dfd.promise

    ###*
    # Get an item from cache if it exists,
    #    otherwise call `closure` and store the results.
    #
    # @param {mixed} key
    # @param {function} closure
    ###
    remember: (key, ttl, closure)->
        dfd = @Q.defer()

        @has(key).then (stored)=>
            if not stored
                closure (data)=> @put(key, data, ttl).then -> dfd.resolve(data)
            else @get(key).then (value)-> dfd.resolve(value)

        return dfd.promise

    ###
    # Just like remember(), get an item from the cache
    # or store the resulting value from the promise.
    #
    # @param {mixed} key
    # @param {function} closure
    ###
    rememberForever: (key, closure)->
        dfd = @Q.defer()

        @has(key).then (stored)=>
            if not stored
                closure (data)=> @forever(key, data).then -> dfd.resolve(data)
            else @get(key).then (value)-> dfd.resolve(value)

        return dfd.promise

    ###
    # Determine if an item exists in the cache.
    #
    # @param {mixed} key
    # @return {Q.promise}
    ###
    has: (key)->
        dfd = @Q.defer()

        key = @getCacheKey(key)

        @Manager.has key, (err, result)->
            return dfd.reject(err) if err
            dfd.resolve(result)

        return dfd.promise

    ###
    # Get the remaining TTL (Time To Live) of an item in the cache.
    #
    # @param {mixed} key
    ###
    ttl: (key)->
        dfd = @Q.defer()

        key = @getCacheKey(key)

        @Manager.ttl key, (err, result)->
            return dfd.reject(err) if err
            dfd.resolve(result)

        return dfd.promise



    ###*
     * Retrieve an item from the cache by key.
     *
     * @param {mixed} key
     * @return {Q.promise}
    ###
    get: (key)->
        dfd = @Q.defer()

        @Manager.get @getCacheKey(key), (err, result)=>
            return dfd.reject(err) if err
            # if there is no results
            # means the key doesn't exist in our cache
            return dfd.resolve(result) if not result

            # When performing numeric operations on
            # values we keep them "as is"
            num = parseInt(result)
            return dfd.resolve(num) if not isNaN(num)

            # get the cached data out of the mapped object
            dfd.resolve(@parseResult(result))

        return dfd.promise

    ###
    # Remove an item from the cache by key.
    #
    # @param {mixed} key
    # @return {Q.promise}
    ###
    forget: (key)->
        dfd = @Q.defer()
        @Manager.del @getCacheKey(key), (err, result)->
            return dfd.reject(err) if err
            dfd.resolve(result)
        return dfd.promise

    ###
    # Remove all items from the cacheKey
    #
    # @return {Q.promise}
    ###
    flush: ->
        dfd = @Q.defer()
        @Manager.flush (err, result)->
            return dfd.reject(err) if err
            dfd.resolve(result)
        return dfd.promise

    ###
    # Increment the value of an item in the cache.
    #
    # @param {mixed} key
    # @param {int} count (Default 1)
    # @return {Q.promise}
    ###
    increment: (key, count = 1)->
        dfd = @Q.defer()
        @Manager.increment @getCacheKey(key), count, (err, result)->
            return dfd.reject(err) if err
            dfd.resolve(result)
        return dfd.promise

    ###
    # Decrement the value of an item in the cache.
    # @param {mixed} key
    # @param {int} count (Default 1)
    # @return {Q.promise}
    ###
    decrement: (key, count = 1)->
        dfd = @Q.defer()
        @Manager.decrement @getCacheKey(key), count, (err, result)->
            return dfd.reject(err) if err
            dfd.resolve(result)
        return dfd.promise

    ###
    # Parse result from the cache store.
    #
    # @param {mixed} result
    # @return {mixed}
    ###
    parseResult: (result)->
        try
            parsed = JSON.parse(result)
            parsed = parsed._cached if parsed?._cached?
        catch e
            parsed = result

        return parsed

# Export class to allow extendability.
module.exports.klass = Cache
# Export instance to allow testability.
module.exports.instance = (Q, Manager, Crypto)-> new Cache(Q, Manager, Crypto)

# Export the method that creates the cache tool.
module.exports.create = (config)->

    Q = require 'q'
    Crypto = require 'crypto'
    Manager = if config? and config?.store? then store else require('./stores/RedisStore').instance(null, config)

    return new Cache(Q, Manager, Crypto, config)
