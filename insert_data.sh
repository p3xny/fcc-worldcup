#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.

INSERT_TEAMS() {
  local TEAMS=()

  while IFS="," read -r YEAR ROUND WINNER OPPONENT WINNER_GOALS OPPONENT_GOALS
  do
    [[ $YEAR == "year" ]] && continue

    TEAMS+=("('$WINNER')" "('$OPPONENT')")
  done < ./games.csv

  local VALUES_SQL
  printf -v VALUES_SQL '%s,' "${TEAMS[@]}"
  VALUES_SQL=${VALUES_SQL%,}

  $PSQL "
    INSERT INTO teams(name)
    SELECT DISTINCT incoming.name
    FROM (VALUES $VALUES_SQL) AS incoming(name)
    WHERE NOT EXISTS (
      SELECT 1
      FROM teams
      WHERE teams.name = incoming.name
    )
    ORDER BY incoming.name;
  "
}

INSERT_GAMES() {
  local GAMES=()

  while IFS="," read -r YEAR ROUND WINNER OPPONENT WINNER_GOALS OPPONENT_GOALS
  do
    [[ "$YEAR" == "year" ]] && continue

      WINNER_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$WINNER';")
      OPPONENT_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$OPPONENT';")

      GAMES+=("($YEAR, '$ROUND', $WINNER_ID, $OPPONENT_ID, $WINNER_GOALS, $OPPONENT_GOALS)" )
  done < ./games.csv

  local VALUES_SQL
  printf -v VALUES_SQL '%s,' "${GAMES[@]}"
  VALUES_SQL=${VALUES_SQL%,}


  echo $GAMES
  $PSQL "
        INSERT INTO
        games
        (year, round, winner_id, opponent_id, winner_goals, opponent_goals)
        VALUES $VALUES_SQL;
        "
}


INSERT_TEAMS
INSERT_GAMES
