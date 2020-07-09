class PartsList < ActiveRecord::Base
  belongs_to :product
  has_many :lots
  has_many :elements, through: :lots
  accepts_nested_attributes_for :lots, allow_destroy: true

  after_save :update_parts_list_json

  validates :name, presence: true
  validates :name, uniqueness: { scope: :product_id, message: "Don't name more than one parts list the same thing for this product" }
  validates :product_id, presence: true
  validates :bricklink_xml, presence: { if: -> { ldr.blank? } }
  validates :ldr, presence: { if: -> { bricklink_xml.blank? } }

  def regenerate_sprite_sheet
    ss = SpriteSheet.new(self)
    ss.generate
  end

  private

  # If I store all of this stuff in here, then I don't get the benefit of automatically
  # picking up changes when a part or element is updated. Maybe if a part/element/color
  # is updated, I can then find all affected parts lists and update them.

  # part name, color name, quantity, link to image (or somehow positioning on a sprite sheet.)
  # structure should look like: (still a WIP)
  # {
  #   "4532_0" => {
  #     "quantity" => 2,
  #     "ldraw_part_num" => "4532",
  #     "bl_part_num" => "4532a",
  #     "part_name" => "Container, Cupboard 2 x 3 x 2",
  #     "color_name" => "Black",
  #     "image_link" => "s3 link", (or) # Not yet stored by the job
  #     "sprite_position" => "something" # Not yet stored by the job
  #   }
  # }
  def update_parts_list_json
    #binding.pry
  end
end
