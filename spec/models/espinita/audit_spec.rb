require 'spec_helper'

module Espinita
  describe Audit do
    it{ should belong_to(:auditable) }
    it{ should belong_to(:user)}
  end
end
