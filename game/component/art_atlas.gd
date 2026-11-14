class_name ArtAtlas

static var frames: Dictionary[String, AtlasTexture] = {}


static func frame(texture: Texture2D, cell_size: Vector2i, index: int) -> AtlasTexture:
	var key := "%s:%s:%d" % [texture.resource_path, cell_size, index]
	if frames.has(key):
		return frames[key]

	var region := Rect2i(Vector2i(index * cell_size.x, 0), cell_size)
	var image := texture.get_image().get_region(region)
	image.convert(Image.FORMAT_RGBA8)
	clear_background(image)
	var atlas := AtlasTexture.new()
	atlas.atlas = ImageTexture.create_from_image(image)
	atlas.region = Rect2(image.get_used_rect().grow(1).intersection(Rect2i(Vector2i.ZERO, image.get_size())))
	frames[key] = atlas
	return atlas


static func clear_background(image: Image) -> void:
	var background := image.get_pixel(0, 0)
	if background.a == 0.0:
		return

	var pending: Array[Vector2i] = []
	var size := image.get_size()
	for x in size.x:
		pending.append(Vector2i(x, 0))
		pending.append(Vector2i(x, size.y - 1))
	for y in size.y:
		pending.append(Vector2i(0, y))
		pending.append(Vector2i(size.x - 1, y))
	while !pending.is_empty():
		var point: Vector2i = pending.pop_back()
		if point.x < 0 or point.y < 0 or point.x >= size.x or point.y >= size.y:
			continue
		if image.get_pixelv(point) != background:
			continue

		image.set_pixelv(point, Color.TRANSPARENT)
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			pending.append(point + direction)
