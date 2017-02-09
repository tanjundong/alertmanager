module Alerts.Views exposing (view)

import Alerts.Types exposing (Alert, AlertGroup, Block, Route(..))
import Alerts.Types exposing (AlertsMsg(..), Msg(..), OutMsg(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Utils.Date
import Utils.Views exposing (..)


alertGroupView : AlertGroup -> Html Msg
alertGroupView alertGroup =
    li [ class "pa3 pa4-ns bb b--black-10" ]
        [ div [ class "mb3" ] (List.map alertHeader <| List.sort alertGroup.labels)
        , div [] (List.map blockView alertGroup.blocks)
        ]


blockView : Block -> Html Msg
blockView block =
    div [] (List.map alertView block.alerts)


alertView : Alert -> Html Msg
alertView alert =
    let
        id =
            case alert.silenceId of
                Just id ->
                    id

                Nothing ->
                    0

        b =
            if alert.silenced then
                buttonLink "fa-deaf" ("#/silences/" ++ toString id) "blue" (ForSelf Noop)
            else
                buttonLink "fa-exclamation-triangle" "#/silences/new" "dark-red" (ForParent (SilenceFromAlert alert))
    in
        div [ class "f6 mb3" ]
            [ div [ class "mb1" ]
                [ b
                , buttonLink "fa-bar-chart" alert.generatorUrl "black" (ForSelf Noop)
                , p [ class "dib mr2" ] [ text <| Utils.Date.dateFormat alert.startsAt ]
                ]
            , div [ class "mb2 w-80-l w-100-m" ] (List.map labelButton <| List.filter (\( k, v ) -> k /= "alertname") alert.labels)
            ]


alertHeader : ( String, String ) -> Html Msg
alertHeader ( key, value ) =
    if key == "alertname" then
        b [ class "db f4 mr2 dark-red dib" ] [ text value ]
    else
        listButton "ph1 pv1" ( key, value )


view : Route -> List AlertGroup -> Html Msg
view route alertGroups =
    let
        groups =
            case route of
                Receiver maybeReceiver maybeShowSilenced ->
                    filterBySilenced maybeShowSilenced <| filterByReceiver maybeReceiver alertGroups
    in
        if List.isEmpty groups then
            div [] [ text "no alerts found found" ]
        else
            ul
                [ classList
                    [ ( "list", True )
                    , ( "pa0", True )
                    ]
                ]
                (List.map alertGroupView groups)


filterBy : (a -> Maybe a) -> List a -> List a
filterBy fn groups =
    List.filterMap fn groups


filterByReceiver : Maybe String -> List AlertGroup -> List AlertGroup
filterByReceiver maybeReceiver groups =
    case maybeReceiver of
        Just receiver ->
            filterBy (filterAlertGroup receiver) groups

        Nothing ->
            groups


filterAlertGroup : String -> AlertGroup -> Maybe AlertGroup
filterAlertGroup receiver alertGroup =
    let
        blocks =
            List.filter (\b -> receiver == b.routeOpts.receiver) alertGroup.blocks
    in
        if not <| List.isEmpty blocks then
            Just { alertGroup | blocks = blocks }
        else
            Nothing


filterBySilenced : Maybe Bool -> List AlertGroup -> List AlertGroup
filterBySilenced maybeShowSilenced groups =
    case maybeShowSilenced of
        Just showSilenced ->
            groups

        Nothing ->
            filterBy filterAlertGroupSilenced groups


filterAlertGroupSilenced : AlertGroup -> Maybe AlertGroup
filterAlertGroupSilenced alertGroup =
    let
        blocks =
            List.filterMap filterSilencedAlerts alertGroup.blocks
    in
        if not <| List.isEmpty blocks then
            Just { alertGroup | blocks = blocks }
        else
            Nothing


filterSilencedAlerts : Block -> Maybe Block
filterSilencedAlerts block =
    let
        alerts =
            List.filter (\a -> not a.silenced) block.alerts
    in
        if not <| List.isEmpty alerts then
            Just { block | alerts = alerts }
        else
            Nothing
