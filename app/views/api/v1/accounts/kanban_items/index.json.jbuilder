json.payload do
  json.array! @items do |item|
    json.partial! 'api/v1/models/kanban_item', formats: [:json], resource: item
  end
end
