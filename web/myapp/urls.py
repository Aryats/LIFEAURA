
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import path
from myapp import views
from vidhya import settings

urlpatterns = [
    path('',views.home,name='home' ),
    path('login/',views.login,name='login'),
    path('adminhome/',views.adminhome,name='adminhome'),
    path('userhome/',views.userhome,name='userhome'),
    path('hospitalhome/',views.hospitalhome,name='hospitalhome'),
    path('organisationhome/',views.organisationhome,name='organisationhome'),
    path('hospital_register/',views.hospital_register,name='hospital_register'),
    path('organization_register/',views.organization_register,name='organization_register'),
    path('admin_add_category/',views.admin_add_category,name='admin_add_category'),
    path('admin_view_categories/',views.admin_view_categories,name='admin_view_categories'),
    path('admin_view_registered_hospitals/',views.admin_view_registered_hospitals,name='admin_view_registered_hospitals'),
    path('admin_approve_hospital/<int:id>',views.admin_approve_hospital,name='admin_approve_hospital'),
    path('admin_reject_hospital/<int:id>',views.admin_reject_hospital,name='admin_reject_hospital'),
    path('admin_view_approved_hospitals/',views.admin_view_approved_hospitals,name='admin_view_approved_hospitals'),
    path('admin_view_registered_organizations/',views.admin_view_registered_organizations,name='admin_view_registered_organizations'),
    path('admin_approve_organization/<int:id>', views.admin_approve_organization, name='admin_approve_organization'),
    path('admin_reject_organization/<int:id>', views.admin_reject_organization, name='admin_reject_organization'),
    path('admin_view_approved_organizations/', views.admin_view_approved_organizations, name='admin_view_approved_organizations'),
    path('admin_view_registered_users/', views.admin_view_registered_users, name='admin_view_registered_users'),
    path('hospital_managment/', views.hospital_managment, name='hospital_managment'),
    path('hospital_profile/', views.hospital_profile, name='hospital_profile'),

    path('blood_managment/<int:id>', views.blood_managment, name='blood_managment'),
    path('my_blood_requests/', views.my_blood_requests, name='my_blood_requests'),

    path('hospital_view_request_blood/', views.hospital_view_request_blood, name='hospital_view_request_blood'),
    path('blood_users/', views.blood_users, name='blood_users'),
    path('accepted_users/', views.accepted_users, name='accepted_users'),
    path('donation_activities/', views.donation_activities, name='donation_activities'),
    path('organisation_profilee/', views.organisation_profilee, name='organisation_profilee'),
    path('organisation_managment/', views.organisation_managment, name='organisation_managment'),

    path("org_event/", views.org_event, name="org_event"),
    path("get_org_events/", views.get_org_events, name="get_org_events"),
    path("delete_event/<int:id>/", views.delete_event, name="delete_event"),

    path('orgblood_request/', views.orgblood_request, name='orgblood_request'),
    path('orgaccept_user/', views.orgaccept_user, name='orgaccept_user'),
    path('logout/', views.logout_view, name='logout'),
    path('user_register/',views.user_register, name='user_register'),
    path('user_login/',views.user_login, name='user_login'),
    path("user_profile/", views.user_profile,name='user_profile'),
    path("donor_list/", views.donor_list, name='donor_list'),
    path("send_request/", views.send_request, name='send_request'),
    path("incoming_request/", views.incoming_request, name='incoming_request'),

    path("chatbot_response/", views.chatbot_response, name="chatbot_response"),

    path("update_request_status/", views.update_request_status, name="update_request_status"),
    path("user_requested_users/", views.user_requested_users),

    path("get_chat_history/", views.get_chat_history),

    path("view_accepted_requests/", views.view_accepted_requests),

    path('org_accepted_users/', views.orgaccept_user, name='orgaccept_user'),
    path('org_chat/<int:id>/', views.org_chat, name='org_chat'),
    path('get_calendar_events/', views.get_calendar_events),
    path('view_blood_banks/', views.view_blood_banks),
    path("send_blood_request/", views.send_blood_request),
    path("user_chat/<int:user_id>/", views.user_chat, name="user_chat"),
    path("view_my_requests/", views.view_my_requests),
    path("user_chat_messages/", views.user_chat_messages),
    path("user_send_message/", views.user_send_message),

    path('view_my_accepted_broadcasts/',views.view_my_accepted_broadcasts),

    path('get_org_chat_messages/<int:id>/', views.get_org_chat_messages, name='get_org_chat_messages'),



    # path("view_matching_users/", views.view_matching_users),
    # path("send_user_blood_request/", views.send_user_blood_request),
    # path("view_received_requests/",views.view_received_requests),
    # path("update_received_request_status/",views.update_received_request_status),


    path("create_broadcast_request/", views.create_broadcast_request),
    path("view_broadcast_requests/", views.view_broadcast_requests),
    path("respond_broadcast_request/", views.respond_broadcast_request),



    path("upload_vitals/",views.upload_vitals, name="upload_vitals"),
    path("view_latest_vitals/",views.view_latest_vitals, name="view_latest_vitals"),

    path('add_meal_time/', views.add_meal_time),
    path('view_meal_time/', views.view_meal_time),
    path("upload_prescription/",views.upload_prescription),
    path('get_upcoming_medicines/', views.get_upcoming_medicines, name='get_upcoming_medicines'),
    path('users_send_chat/', views.users_send_chat),
    path('users_view_chat/', views.users_view_chat),
    path('leaderboard_users/', views.leaderboard_users),
    path('view_my_broadcast_requests/', views.view_my_broadcast_requests),



]
