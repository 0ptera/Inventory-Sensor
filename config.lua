-- how often in ticks should inventories be updated
update_interval = 10

-- how often should be scanned for changed entities
-- trains moving out of the station, furnaces deconstructed, etc
find_entity_interval = 100

-- half width of search BoundingBox
-- 0.2 tested to work on corners of vanilla traincars
BBox_offset = 0.2 
-- length of search BoundingBox
BBox_range = 1.5 