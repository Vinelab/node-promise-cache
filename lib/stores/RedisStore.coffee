extend = require 'extend'

class Store

    constructor: (@pool)->

    ###
    # Connect to store.
    #
    # @param {function} cb
    ###
    connect: (cb)-> @pool.acquire (err, conn)=>
        if err
            @pool.release(conn)
            return cb(err) if typeof cb is 'function'

        conn.select(0)
        cb(null, conn) if typeof cb is 'function'

    ###
    # Set an item by key.
    #
    # @param {string} key
    # @param {string} value
    # @param {function} cb
    ###
    set: (key, value, cb)-> @connect (err, conn)=>
        return cb(err) if err

        conn.set key, value, (err, result)=>
            @pool.release(conn)
            cb(err, result)

    ###
    # Set an item by key for a certain number of minutes.
    #
    # @param {string} key
    # @param {string} value
    # @param {int} ttl
    # @param {function} cb
    ###
    setFor: (key, value, ttl, cb)-> @connect (err, conn)=>
        return cb(err) if err

        conn.setex key, ttl, value, (err, result)=>
            @pool.release(conn)
            cb(err, result)

    ###
    # Determine whether an item exists in the store.
    #
    # @param {string} key
    # @param {function} cb
    ###
    has: (key, cb)-> @connect (err, conn)=>
        return cb(err) if err

        conn.exists key, (err, result)=>
            @pool.release(conn)
            cb(err, Boolean result)

    ###
    # Get the TTL of an item.
    #
    # @param {string} key
    # @param {function} cb
    ###
    ttl: (key, cb)-> @connect (err, conn)=>
        return cb(err) if err

        conn.ttl key, (err, result)=>
            @pool.release(conn)
            cb(err, result)

    ###
    # Get an item from the store.
    #
    # @param {string} key
    # @param {function} cb
    ###
    get: (key, cb)-> @connect (err, conn)=>
        return cb(err) if err

        conn.get key, (err, result)=>
            @pool.release(conn)
            cb(err) if err
            cb(null, result) if typeof cb is 'function'

    ###
    # Delete an item from the store.
    #
    # @param {string} key
    # @param {function} cb
    ###
    del: (key, cb)-> @connect (err, conn)=>
        return cb(err) if err

        conn.del key, (err, result)=>
            @pool.release(conn)
            cb(err, Boolean result) if typeof cb is 'function'

    ###
    # Flush the store.
    #
    # @param {function} cb
    ###
    flush: (cb)-> @connect (err, conn)=>
        return cb(err) if err

        conn.flushdb (err, result)=>
            @pool.release(conn)
            cb(err, result) if typeof cb is 'function'

    ###
    # Increment the integer value of a key by @count.
    #
    # @param {string} key
    # @param {int} count
    # @param {function} cb
    ###
    increment: (key, count, cb)-> @connect (err, conn)=>
        return cb(err) if err

        conn.incrby key, count, (err, result)=>
            @pool.release(conn)
            cb(err, result) if typeof cb is 'function'

    decrement: (key, count, cb)-> @connect (err, conn)=>
        return cb(err) if err

        conn.decrby key, count, (err, result)=>
            @pool.release(conn)
            cb(err, result) if typeof cb is 'function'

# Export class to allow extendability.
module.exports.klass = Store
# Export instance to allow testability and custom initialization.
module.exports.instance = (pool, config = {})->

    # If an existing pool was passed, we'll just use it.
    return new Store(pool) if pool?

    # Setup configuration.
    config = extend(yes, {
        redis:
            host: '127.0.0.1',
            port: 6379
            pool: {max: 1, min: 2}
    }, config)

    # Create the redis pool.
    RedisPool = require('sol-redis-pool')
    # Prepare and return the pool.
    pool = new RedisPool({
        host: config.redis.host
        port: config.redis.port
    }, {
        max: config.redis.pool.max
        min: config.redis.pool.minutes
    })

    return new Store(pool)
