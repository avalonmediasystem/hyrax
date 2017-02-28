describe "Browse Dashboard", type: :feature do
  let(:user) { create(:user) }
  let!(:dissertation) { create(:public_work, user: user, title: ["Fake PDF Title"], subject: %w(lorem ipsum dolor sit amet)) }
  let!(:mp3_work) { create(:public_work, user: user, title: ["Test Document MP3"], subject: %w(consectetur adipisicing elit)) }

  before do
    sign_in user
    create(:public_work, user: user, title: ["Fake Wav Files"], subject: %w(sed do eiusmod tempor incididunt ut labore))
    visit "/dashboard/my/works"
  end

  it "lets the user search and display their files" do
    fill_in "q", with: "PDF"
    click_button "search-submit-header"
    expect(page).to have_content("Fake PDF Title")
    within(".constraints-container") do
      expect(page).to have_content("Filtering by:")
      expect(page).to have_css("span.glyphicon-remove")
      find(".dropdown-toggle").click
    end
    expect(page).to have_content("Fake Wav File")

    # Browse facets
    click_button "Status"
    click_link "Published"
    within("#document_#{mp3_work.id}") do
      expect(page).to have_link("Display all details of Test Document MP3",
                                href: hyrax_generic_work_path(mp3_work, locale: 'en'))
    end
    click_link("Remove constraint Status: Published")

    within("#document_#{dissertation.id}") do
      click_button("Select an action")
      expect(page).to have_content("Edit Work")
    end
  end

  it "allows me to delete works in upload_sets", js: true do
    first('input#check_all').click
    expect do
      click_button('Delete Selected')
    end.to change { GenericWork.count }.by(-3)
  end
end
