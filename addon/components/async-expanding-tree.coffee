`import Ember from 'ember'`
`import layout from '../templates/components/async-expanding-tree'`

AsyncExpandingTreeComponent = Ember.Component.extend
  layout: layout
  classNames: ["aet"]
  # default configuration
  config:
    # property path to the property that should be used as label
    # e.g. model.label.en would be label.en
    labelPropertyPath: 'label'
    # function that is called with the selected model when the label of the model is clicked
    onActivate: (model) ->
    # function to retrieve children of the parent object
    # this function should return a Promise that has updated model.children when succeeded
    getChildren: (model) ->
      model.reload()
    # list of concept ids that are expanded
    # will auto expand a node in the tree if it's id is contained in this array
    expandedConcepts: []
    # max amount (n) of children to be shown before a load more button is presented
    # load more button shows an extra n children
    showMaxChildren: 50
    # route used in link-to of the node
    linkToRoute: 'concepts.show'
    # show nodes without children
    includeLeafs: true
  fetchChildrenOnInit: false

  init: () ->
    @_super(arguments)
    if @get('fetchChildrenOnInit')
      @fetchChildren()
    if @get('expandedConcepts')?.contains(@get('model.id')) and not @get('expanded')
      @toggleExpandF()

  labelPropertyPath: Ember.computed.alias 'config.labelPropertyPath'
  getChildren: Ember.computed.alias 'config.getChildren'
  expandedConcepts: Ember.computed.alias 'config.expandedConcepts'
  showMaxChildren: Ember.computed.alias 'config.showMaxChildren'
  linkToRoute: Ember.computed.alias 'config.linkToRoute'
  label: Ember.computed 'labelPropertyPath', 'model', ->
    @get("model.#{@get('labelPropertyPath')}")
  sortedChildren: Ember.computed.sort 'model.children', 'sortchildrenby'
  sortchildrenby: Ember.computed 'labelPropertyPath', ->
    [@get('labelPropertyPath')]
  childrenFetched: false
  childrenSlice: 50
  expandable: Ember.computed 'model.children', 'loading',  ->
    (not @get('loading')) and @get('model.children.length')
  showLoadMore: Ember.computed 'model.children.length', 'childrenSlice', 'loading', ->
    (!@get('loading')) && @get('childrenSlice') < @get('model.children.length')
  expanded: false
  loading: false
  tagName: 'li'
  showSublist: Ember.computed 'config.includeLeafs', ->
    if @get('model.children.length') > 0
      @get('config.includeLeafs')
    else
      true
  fetchChildren: ->
    @set('loading', true)
    @get('getChildren')(@get('model')).then(=>
      @set 'loading', false
      @set 'childrenFetched', true
      if @get('model.children.length') > 0
        @set 'children', @get('sortedChildren').slice(0, @get('showMaxChildren'))
        @set 'childrenSlice', @get('showMaxChildren')
    ).catch(=> @set 'loading', false)
  toggleExpandF: ->
    @toggleProperty('expanded')
    if @get('expanded')
      @fetchChildren() unless @get('childrenFetched')
      @get('expandedConcepts').addObject(@get('model.id'))
    else
      @get('expandedConcepts').removeObject(@get('model.id'))
  actions:
    clickItem: ->
      @get('config.onActivate')?(@get('model'))
    toggleExpand: ->
      @toggleExpandF()
    loadMoreChildren: ->
      if @get('childrenSlice') + @get('showMaxChildren') > @get('model.children.length')
        newSlice = @get('model.children.length')
      else
        newSlice = @get('childrenSlice') + @get('showMaxChildren')
      extraSlice = @get('sortedChildren').slice(@get('childrenSlice'), newSlice)
      @get('children').pushObjects(extraSlice)
      @set('childrenSlice', newSlice)


`export default AsyncExpandingTreeComponent`
