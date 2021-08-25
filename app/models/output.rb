class Output < ApplicationRecord
  belongs_to :download

  self.inheritance_column = "type_class"

  enum type: [:out, :err]

  broadcasts_to ->(output) { [:downloads, output.download] }
end
