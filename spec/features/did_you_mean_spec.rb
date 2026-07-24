require 'rails_helper'

describe 'did you mean? feature' do
    it 'suggests a correction to a typo' do
        visit '/?group=true&search_field=all_fields&q=miscelaneous'
        expect(page).to have_content 'Did you mean to type'
        expect(page).to have_link 'miscellaneous'
    end
    it 'suggests a correction to a misspelled name' do
        visit '/?group=true&search_field=all_fields&q=einstien'
        expect(page).to have_content 'Did you mean to type'
        expect(page).to have_link 'einstein'
    end
    it 'suggests that user remove extra space from name' do
        visit '/?group=true&search_field=all_fields&q=j.+paul+bald+eagle'
        expect(page).to have_content 'Did you mean to type'
        expect(page).to have_link 'baldeagle'
    end
end
