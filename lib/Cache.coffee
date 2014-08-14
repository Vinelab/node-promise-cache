class Cache

    ###
    # Create a new Cache instance.
    #
    # @param {object} Q The promise manager.
    # @param {object} Manager The cache store manager. (check /lib/stores)
    # @param {object} Crypto node's crypto module
    # @return Cache
    ###
    constructor: (@Q, @Manager, @Crypto)->
        @prefix = 'pcache'
        @default_ttl = 1

    ###*
     # Get the cache key.
     #
     # @param {mixed} key
     # @return string
    ###
    getCacheKey: (key)=>
        return "#{@prefix}:#{key}" if typeof key is 'string'

        hash = @Crypto.createHash('md5')
        .update(JSON.stringify({_key: key})).digest('hex')
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
     * Get an item from cache if it exists,
     * otherwise execute and get the value from the promise.
     *
     * @param {mixed} key
     * @param {Q.promise}
    ###
    remember: (key, ttl, promise)->
        dfd = @Q.defer()

        @get(key).then (stored)=>
            if not stored
                promise.then (data)=>
                    @put(key, data, ttl).then -> dfd.resolve(data)
            else dfd.resolve(stored)

        return dfd.promise

    ###
    # Just like remember(), get an item from the cache
    # or store the resulting value from the promise.
    #
    # @param {mixed} key
    # @param {Q.promise}
    ###
    rememberForever: (key, promise)->
        dfd = @Q.defer()

        @get(key).then (stored)=>
            if not stored
                promise.then (data)=>
                    @forever(key, data)
                    dfd.resolve(data)
            else dfd.resolve(stored)

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

        @Manager.get @getCacheKey(key), (err, result)->
            return dfd.reject(err) if err
            # if there is no results
            # means the key doesn't exist in our cache
            return dfd.resolve(result) if not result

            # When performing numeric operations on
            # values we keep them "as is"
            num = parseInt(result)
            return dfd.resolve(num) if not isNaN(num)

            # get the cached data out of the mapped object
            reduced = JSON.parse(result)._cached
            dfd.resolve(reduced)

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

# Export class to allow extendability.
module.exports.klass = Cache
# Export instance to allow testability.
module.exports.instance = (Q, Manager, Crypto)-> new Cache(Q, Manager, Crypto)

# Export the method that creates the cache tool.
module.exports.create = (config)->

    Q = require 'q'
    Crypto = require 'crypto'
    Manager = if config? and config?.store? then store else require('./stores/RedisStore').instance(null, config)

    return new Cache(Q, Manager, Crypto)
