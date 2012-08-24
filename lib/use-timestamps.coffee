module.exports = (schema, options) ->
  schema.add createdAt: Date, updatedAt: Date
  schema.pre 'save', (next) ->
    @createdAt ?= @updatedAt = new Date
    next()
