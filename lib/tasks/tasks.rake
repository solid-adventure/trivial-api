namespace :tasks do
  desc "Migrate the from and to stage ids"
  task migrate_stages: :environment do
    Connection.all.each do |connection|
      connection.from_stage_id = connection.from_id
      connection.to_stage_id = connection.to_id

      connection.save
    end
  end

  desc "Seed from, to values in connections"
  task import_from_to: :environment do
    data = [
      # Mailchimp, http://withtrivial.com/boards/f72d542be2764ea3ac0bcfaddf0bb389/edit
      {id: 95, from: 'a', to: 'table'},
      # Trivial Splash Page, http://withtrivial.com/boards/e91f194a20f3e79d43875eb62f2b3dd5/edit 
      {id: 7, from: 'b', to: 'c'},
      {id: 11, from: 'c', to: 'b'},
      # Trivial Board Management, http://withtrivial.com/boards/92cf04fc58332fcbbffaf02e5e8dd520/edit 
      {id: 12, from: 'a', to: 'b'},
      {id: 13, from: 'c', to: 'a'},
      {id: 14, from: 'a', to: 'c'},

      # Whiplash Search & Simulate, http://withtrivial.com/boards/d777d56795b932b2d04b9805c1f041e2/edit
      {id: 59, from: 'searchBox', to: 'apiCall'},
      {id: 60, from: 'apiCall', to: 'searchBox'},
      {id: 61, from: 'searchBox.simulateButton', to: 'apiCall'},
      # Trivial Board Settings, http://withtrivial.com/boards/dc57e8058701598ac10af72b9a7378b7/edit
      {id: 15, from: 'b.deleteBoardButton', to: 'c'},
      {id: 16, from: 'c', to: 'b'},
      {id: 17, from: 'c', to: 'b'},
      {id: 18, from: 'c', to: 'b.deleteBoardButton'},
      {id: 19, from: 'c', to: 'b.deleteBoardButton'},
      {id: 20, from: 'c', to: 'b.deleteBoardButton'},
      # Whiplash Simulate Workflow, http://withtrivial.com/boards/7d1cfdd18f96e1c0451be54ee34d0c23/edit
      {id: 29, from: 'a', to: 'Whiplash'},
      {id: 30, from: 'Whiplash', to: 'a'},
      {id: 31, from: 'Whiplash', to: 'a'},
      {id: 32, from: 'a', to: 'Whiplash'},
      # Dropbox Oauth, http://withtrivial.com/boards/4fd460c992bdb42f04434cfa918c2b10/edit
      {id: 62, from: 'a', to: 'Dropbox'},
      {id: 63, from: 'Dropbox', to: 'a'},
      # Signup-banner, http://withtrivial.com/boards/47bc5bfbf5a5975d9624a7ed3869894d/edit
      {id: 94, from: 'a', to: 'b'},
      {id: 96, from: 'b', to: 'c'},
      # Spotify Demo, http://withtrivial.com/boards/164498cbb22c6f880774ddec92b980a8/edit
      {id: 102, from: 'setCookie', to: 'tokenRequest'}, 
      {id: 86, from: 'Spotify', to: 'tokenRequest'},
      {id: 87, from: 'tokenRequest', to: 'setCookie'},
      # Status Endpoint Demo, http://withtrivial.com/boards/4ad544e4d1a9a2e0fb71e3eeb1130a9f/edit
      {id: 64, from: 'c', to: 'Whiplash'},
      {id: 65, from: 'Whiplash', to: 'c'},
      {id: 66, from: 'c', to: 'Whiplash'},
      {id: 67, from: 'Whiplash', to: 'c'},
      {id: 68, from: 'Whiplash', to: 'c'},
      {id: 69, from: 'c', to: 'Whiplash'},
      # carousel test http://withtrivial.com/boards/e13ef1c42085a6050190f42b54a3357a/edit
      {id: 97, from: 'playlists', to: 'carousel'},
      # Trivial User Settings, http://withtrivial.com/boards/22b2c838469a0b803b30a88b7cc9aedb/edit
      {id: nil, from:'a', to: 'b'},
      # Logged In Name, http://withtrivial.com/boards/bbdfcbb6073929053810b30272f65adf/edit
      {id: 101, from: 'a', to: 'b'},
      # Spotify Doorkeeper, http://withtrivial.com/boards/e5cfea59bc56df3813aa93389ce0616c/edit
      {id: 103, from: 'spotifyStatus', to: 'router'},
      # login-banner, http://withtrivial.com/boards/8135d3a1270e7fe349b788013372b340/edit
      {id: 79, from: 'a', to: 'b'},
      {id: 80, from: 'b', to: 'c'},
      # Set Board Name http://withtrivial.com/boards/e41827865bd6f9c0b207beac7de6782a/edit
      {id: 107, from: 'Display', to: 'APICall'},
      {id: 108, from: 'APICall', to: 'Response'}
    ]

    missing_ids = []

    data.each do |h|
      connection = Connection.find_by(id: h[:id])
      if connection
        connection.from = h[:from]
        connection.to = h[:to]
        connection.save
      else
        missing_ids << h[:id]
      end
    end

    p "Missing IDs: #{missing_ids.join(', ')}"
  end
end
