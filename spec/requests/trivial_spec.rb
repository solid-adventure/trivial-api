require 'swagger_helper'

describe 'Auth API', skip: true do

  path '/auth' do

    post 'Register a user' do
      tags 'Auth'
      consumes 'application/json'
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string },
          password: { type: :string },
          name: { type: :string },
          team_id: { type: :integer }
        },
        required: [ 'email', 'password', 'name' ]
      }

      response '200', 'user created' do
        schema type: :object,
          properties: {
            status: { type: :integer },
            data: { type: :object, properties: {
              id: { type: :integer },
              provider: { type: :string },
              uid: { type: :string },
              name: { type: :string },
              email: { type: :string },
              created_at: { type: :string },
              updated_at: { type: :string },
              team_id:  { type: :integer, nullable: true },
              role: { type: :string },
              approval: { type: :string }
            }},
          }

        examples 'application/json' => {
          "status": "success",
          "data": {
              "id": 7,
              "provider": "email",
              "uid": "test215@email.com",
              "name": "test15",
              "email": "test215@email.com",
              "created_at": "2020-12-15T14:39:13.393Z",
              "updated_at": "2020-12-15T14:39:13.461Z",
              "team_id": 3,
              "role": "member",
              "approval": "approved"
          }
      }

        run_test!
      end

      response '400', 'bad request - wrong format of parameters' do
        run_test!
      end

      response '422', 'unprocessable entity - email taken; name, email, password blank or too short!' do
        run_test!
      end
    end

  end

  path '/auth/sign_in' do

    post 'Sign in a user' do
      tags 'Auth'
      consumes 'application/json'
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string },
          password: { type: :string }
        },
        required: [ 'email', 'password' ]
      }

      response '200', 'user logged in' do
        schema type: :object, properties: {
            data: {
              type: :object, properties: {
                id: { type: :integer },
                provider: { type: :string },
                uid: { type: :string },
                name: { type: :string },
                email: { type: :string },
                created_at: { type: :string },
                updated_at: { type: :string },
                team_id:  { type: :integer, nullable: true },
                role: { type: :string },
                approval: { type: :string }
              }
            }
          }

        run_test!
      end

      response '400', 'bad request - wrong format of request data' do
        run_test!
      end

      response '401', 'unauthorized - email or password is wonrg' do
        run_test!
      end
    end

  end

  path '/auth/sign_out' do

    delete 'Sign out a user' do
      tags 'Auth'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'

      response '200', 'user signed out' do

        schema type: :object, properties: {
            data: {
              type: :object, properties: {
                id: { type: :integer },
                provider: { type: :string },
                uid: { type: :string },
                name: { type: :string },
                email: { type: :string },
                created_at: { type: :string },
                updated_at: { type: :string },
                team_id:  { type: :integer, nullable: true },
                role: { type: :string },
                approval: { type: :string }
              }
            }
          }

        run_test!
      end

      response '401', 'unauthrorized - invalid login credentials in the header' do
        run_test!
      end

    end

  end

end

describe 'Teams API', skip: true do

  path '/teams' do

    get 'Show the list of the teams' do
      tags 'Team'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'

      response '200', 'team listed - only for admin' do
        run_test!
      end

      response '401', 'unauthorized - not logged in or not admin' do
        run_test!
      end
    end

    post 'Create a team' do
      tags 'Team'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'

      parameter name: :team, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
        },
        required: [ 'name' ]
      }

      response '201', 'team created' do
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

  path '/teams/{teamId}' do
    get 'Show the team with teamId' do
      tags 'Team'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'
      parameter name: "teamId", in: :path, type: :string

      response '200', 'show team' do
        run_test!
      end
    end

    put 'Update the team with teamId' do
      tags 'Team'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'

      response '200', 'team updated' do
        run_test!
      end

      response '400', 'bad request' do
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end
    end

    delete 'Destroy the team with teamId' do
      tags 'Team'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'

      response '204', 'team deleted' do
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

describe 'Users API', skip: true do
  path '/users' do

    get 'Show the list of the users' do
      tags 'User'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'

      response '200', 'users listed' do
        run_test!
      end

      response '400', 'bad request' do
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end
    end

    post 'Create a user' do
      tags 'User'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'

      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          email: { type: :string },
          password: { type: :string },
          team_id: { type: :integer },
          role: { type: :string },
          approval: { type: :string }
        },
        required: [ 'email', 'password', 'name' ]
      }

      response '201', 'user created' do
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

  path '/users/{userId}' do
    get 'Show the user with userId' do
      tags 'User'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'
      parameter name: "userId", in: :path, type: :string

      response '200', 'show user' do
        run_test!
      end
    end

    put 'Update the User with userId' do
      tags 'User'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          email: { type: :string },
          password: { type: :string },
          team_id: { type: :integer },
          role: { type: :string },
          approval: { type: :string }
        },
        required: [ 'email', 'password', 'name' ]
      }

      response '200', 'user updated' do
        run_test!
      end

      response '400', 'bad request' do
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end
    end

    delete 'Destroy the team with userId' do
      tags 'User'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'

      response '204', 'user deleted' do
        run_test!
      end

      response '400', 'bad request' do
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end

      response '422', 'unprocessable entity - when try to delete team manager' do
        run_test!
      end
    end
  end
end

describe 'Members API', skip: true do
  path '/members' do

    get 'Show the list of the members' do
      tags 'Member'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'

      response '200', 'members listed' do
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

  path '/members/{userId}' do
    get 'Show the member with userId' do
      tags 'Member'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'

      parameter name: "userId", in: :path, type: :string

      response '200', 'show member' do
        run_test!
      end

      response '400', 'bad request' do
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end
    end

    put 'Update the Member with userId' do
      tags 'Member'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'

      parameter name: :member, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          password: { type: :string },
          approval: { type: :string },
        },
      }

      response '200', 'member updated' do
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

describe 'Boards API', skip: true do
  path '/boards' do

    get 'Show the list of the boards' do
      tags 'Board'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'


      response '200', 'boards listed' do
        run_test!
      end

      response '400', 'bad request' do
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end
    end

    post 'Create a board' do
      tags 'Board'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'

      parameter name: :board, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          access_level: { type: :string },
          contents: { type: :string },
        },
        required: [ 'name' ]
      }

      response '201', 'board created' do
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

  path '/boards/{boardId}' do
    get 'Show the board with boardId' do
      tags 'Board'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'

      parameter name: "boardId", in: :path, type: :string

      response '200', 'show board' do
        run_test!
      end

      response '400', 'bad request' do
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end
    end

    put 'Update the Board with boardId' do
      tags 'Board'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'

      parameter name: :board, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          access_level: { type: :string },
          contents: { type: :string },
        },
      }

      response '200', 'member updated' do
        run_test!
      end

      response '400', 'bad request' do
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end
    end

    delete 'Destroy the board with boardId' do
      tags 'Board'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'


      response '204', 'board deleted' do
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

describe 'Flows API', skip: true do
  path '/flows' do

    post 'Create a flow' do
      tags 'Flow'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'

      parameter name: :flow, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          access_level: { type: :string },
          contents: { type: :string },
        },
        required: [ 'name' ]
      }

      response '201', 'flow created' do
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

  path '/flows/{flowId}' do
    get 'Show the flow with flowId' do
      tags 'Flow'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'

      parameter name: "flowId", in: :path, type: :string

      response '200', 'show flow' do
        run_test!
      end

      response '400', 'bad request' do
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end
    end

    put 'Update the User with flowId' do
      tags 'Flow'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'

      parameter name: :flow, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          access_level: { type: :string },
          contents: { type: :string },
        },
      }

      response '200', 'flow updated' do
        run_test!
      end

      response '400', 'bad request' do
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end
    end

    delete 'Destroy the team with flowId' do
      tags 'Flow'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'

      response '204', 'flow deleted' do
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

describe 'Stages API', skip: true do
  path '/stages' do

    post 'Create a stage' do
      tags 'Stage'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'

      parameter name: :stage, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          subcomponents: { type: :string },
          contents: { type: :string },
        },
        required: [ 'name' ]
      }

      response '201', 'stage created' do
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

  path '/stages/{stageId}' do
    get 'Show the stage with stageId' do
      tags 'Stage'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'

      parameter name: "stageId", in: :path, type: :string

      response '200', 'show stage' do
        run_test!
      end

      response '400', 'bad request' do
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end
    end

    put 'Update the User with stageId' do
      tags 'Stage'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'

      parameter name: :stage, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          access_level: { type: :string },
          contents: { type: :string },
        },
      }

      response '200', 'stage updated' do
        run_test!
      end

      response '400', 'bad request' do
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end
    end

    delete 'Destroy the team with stageId' do
      tags 'Stage'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'


      response '204', 'stage deleted' do
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

describe 'Connections API', skip: true do
  path '/connections' do

    post 'Create a connection' do
      tags 'Connection'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'

      parameter name: :connection, in: :body, schema: {
        type: :object,
        properties: {
          form_id: { type: :integer },
          to_id: { type: :integer },
          transform: { type: :string },
        },
        required: [ 'name' ]
      }

      response '201', 'connection created' do
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

  path '/connections/{connectionId}' do
    get 'Show the connection with connectionId' do
      tags 'Connection'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'

      parameter name: "connectionId", in: :path, type: :string

      response '200', 'show connection' do
        run_test!
      end

      response '400', 'bad request' do
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end
    end

    put 'Update the User with connectionId' do
      tags 'Connection'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'

      parameter name: :connection, in: :body, schema: {
        type: :object,
        properties: {
          form_id: { type: :integer },
          to_id: { type: :integer },
          transform: { type: :string },
        },
        required: [ 'name' ]
      }

      response '200', 'connection updated' do
        run_test!
      end

      response '400', 'bad request' do
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end
    end

    delete 'Destroy the team with connectionId' do
      tags 'Connection'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'

      response '204', 'connection deleted' do
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
