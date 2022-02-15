require 'swagger_helper'


describe 'Profiles API', skip: true do

  path '/profiles' do
    get 'Show user profile' do
      tags 'Profile'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'

      response '200', 'show profile' do
        run_test!
      end

      response '400', 'bad request' do
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end

      response '422', 'unprocessable entity - when user try to change the team' do
        run_test!
      end

    end

    put 'Update user profile' do
      tags 'Profile'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'

      response '200', 'update profile' do
        run_test!
      end

      response '400', 'bad request' do
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end
    end
  end

end


