module ApplicationHelper
  INPUT_CLASSES = "block shadow-sm rounded-md border border-gray-400 focus:outline-pink-600 px-3 py-2 mt-2 w-full".freeze
  PRIMARY_BUTTON_CLASSES = "rounded-md px-3.5 py-2.5 bg-pink-600 hover:bg-pink-500 text-white font-medium cursor-pointer".freeze
  SECONDARY_BUTTON_CLASSES = "rounded-md px-3.5 py-2.5 bg-gray-200 hover:bg-gray-300 font-medium cursor-pointer".freeze

  def input_classes = INPUT_CLASSES
  def primary_button_classes = PRIMARY_BUTTON_CLASSES
  def secondary_button_classes = SECONDARY_BUTTON_CLASSES
end
