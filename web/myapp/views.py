from django.contrib.auth import authenticate ,login as auth_login
from django.contrib.auth.decorators import login_required
from django.contrib.auth.models import User ,Group
from django.views.decorators.cache import never_cache
from myapp.models import*
from django.contrib.auth.decorators import login_required
from .models import Prescription, MedicineSchedule
from django.contrib.auth import authenticate
import google.generativeai as genai
from django.conf import settings
from django.views.decorators.csrf import csrf_exempt
from django.utils import timezone
from datetime import datetime
from django.http import JsonResponse
from .models import BloodRequest, Organization, UserProfile
from django.shortcuts import render, redirect
from django.contrib.auth.decorators import login_required
from django.utils import timezone
from django.contrib import messages
from .models import CalendarEvent

from django.db import transaction

genai.configure(api_key=settings.GEMINI_API_KEY)



def home(request):
    return render(request,'public_home.html')

# -----------------------------------------------------------------------------------------------------------------------------

@csrf_exempt
def login(request):
    if request.method == 'POST':
        username = request.POST['username']
        password = request.POST['password']

        user = authenticate(request, username=username, password=password)
        # print(username,password)
        if user is not None:
            auth_login(request, user)
            request.session['user_id'] = user.id

            if user.groups.filter(name='admin').exists():
                return redirect('adminhome')

            elif user.groups.filter(name='hosspitals').exists():
                hospital = Hospital.objects.get(USER=user)
                request.session['hospital_id'] = hospital.id

                if hospital.status=='approved':
                    return redirect('hospitalhome')
                elif hospital.status =='rejected':
                    messages.error(request,'your request is rejected')
                    return redirect('login')
                else:
                    messages.error(request, "your request is pending approval")
                    return redirect('login')

            elif user.groups.filter(name='organisations').exists():
                organisations = Organization.objects.get(USER=user)
                request.session['organisations_id'] = organisations.id

                if organisations.status == 'approved':
                    return redirect('organisationhome')
                elif organisations.status == 'rejected':
                    messages.error(request, 'your request is rejected')
                    return redirect('login')
                else:
                    messages.error(request, "your request is pending approval")
                    return redirect('login')
        else:
            messages.error(request, "invalid username or password")
            return redirect('login')


    return render(request,'login.html')

# -----------------------------------------------------------------------------------------------------------------------------

@login_required
@csrf_exempt
@never_cache
def adminhome(request):
    return render(request,'adminhome.html')

# -----------------------------------------------------------------------------------------------------------------------------

def userhome(request):
    return render(request, 'hospitalhome.html')

# -----------------------------------------------------------------------------------------------------------------------------

def hospitalhome(request):
    return render(request,'hospitalhome.html')

# -----------------------------------------------------------------------------------------------------------------------------
def organisationhome(request):
    return render(request,'organisationhome.html')

# -----------------------------------------------------------------------------------------------------------------------------

@csrf_exempt
def hospital_register(request):
    if request.method=='POST':
        hospital_name=request.POST['hospital_name']
        address=request.POST['address']
        email=request.POST['email']
        phone=request.POST['phone']
        username=request.POST['username']
        password=request.POST['password']

        if User.objects.filter(username=username).exists():
            messages.error(request,'username already exists')
            return redirect('hospital_register')

        user=User.objects.create_user(username=username,password=password)
        user.save()

        group=Group.objects.get(name='hosspitals')
        user.groups.add(group)

        Hospital.objects.create(USER=user,hospital_name=hospital_name,address=address,email=email,phone=phone,status='pending')

        messages.success(request,'registration successfull')
        return redirect('login')

    return render(request,'hospital_register.html')


@csrf_exempt
def organization_register(request):
    if request.method == 'POST':
        organisation_name = request.POST['organisation_name']
        address = request.POST['address']
        email = request.POST['email']
        phone = request.POST['phone']
        category_id = request.POST['category']
        username = request.POST['username']
        password = request.POST['password']

        if User.objects.filter(username=username).exists():
            messages.error(request, 'Username already exists')
            return redirect('organization_register')

        user = User.objects.create_user(
            username=username,
            password=password
        )
        user.save()

        group = Group.objects.get(name='organisations')
        user.groups.add(group)

        category = Category.objects.get(id=category_id)

        Organization.objects.create(
            USER=user,
            category=category,
            organisation_name=organisation_name,
            email=email,
            phone=phone,
            address=address,
            status='pending'
        )

        messages.success(request, 'Organization registration successful. Waiting for approval.')
        return redirect('login')

    categories = Category.objects.all()
    return render(request, 'organization_register.html', {'categories': categories})


@login_required
@never_cache
@csrf_exempt
def admin_add_category(request):
    if request.method == 'POST':
        category_name = request.POST['category_name']

        Category.objects.create(
            category_name=category_name
        )

        messages.success(request, 'Category added successfully.')
        return redirect('admin_view_categories')

    return render(request, 'admin_add_category.html')



@login_required
@never_cache
@csrf_exempt
def admin_view_categories(request):
    a=Category.objects.all()
    return render(request,'admin_view_categories.html',{'b':a})


@login_required
@csrf_exempt
@never_cache
def admin_view_registered_hospitals(request):
    hospitals = Hospital.objects.all()
    return render(
        request,
        'admin_view_registered_hospitals.html',
        {'hospitals': hospitals}
    )


@login_required
@csrf_exempt
@never_cache
def admin_approve_hospital(request, id):
    hospital = Hospital.objects.get(id=id)
    hospital.status = 'approved'
    hospital.save()
    return redirect('admin_view_registered_hospitals')


@login_required
@csrf_exempt
@never_cache
def admin_reject_hospital(request, id):
    hospital = Hospital.objects.get(id=id)
    hospital.status = 'rejected'
    hospital.save()
    return redirect('admin_view_registered_hospitals')

@login_required
@csrf_exempt
@never_cache
def admin_view_approved_hospitals(request):
    hospitals = Hospital.objects.filter(status='approved')
    return render(
        request,
        'admin_view_approved_hospitals.html',
        {'hospitals': hospitals}
    )


@login_required
@csrf_exempt
@never_cache
def admin_view_registered_organizations(request):
    organizations = Organization.objects.all()
    return render(
        request,
        'admin_view_registered_organizations.html',
        {'organizations': organizations}
    )


@login_required
@csrf_exempt
@never_cache
def admin_approve_organization(request, id):
    organization = Organization.objects.get(id=id)
    organization.status = 'approved'
    organization.save()
    return redirect('admin_view_registered_organizations')


@login_required
@csrf_exempt
@never_cache
def admin_reject_organization(request, id):
    organization = Organization.objects.get(id=id)
    organization.status = 'rejected'
    organization.save()
    return redirect('admin_view_registered_organizations')

def hospital_managment(request):
    hospital = Hospital.objects.get(id=request.session['hospital_id'])

    if request.method == 'POST':
        hospital.hospital_name = request.POST.get('hospital_name')
        hospital.email = request.POST.get('email')
        hospital.phone = request.POST.get('phone')
        hospital.address = request.POST.get('address')
        hospital.save()

        return redirect('hospital_profile')

    return render(request, 'hospital_managment.html', {'hospital': hospital})



def hospital_profile(request):
    hospitals = Hospital.objects.get(id=request.session['hospital_id'])
    return render(request,'hospital_profile.html',{'hospitals':hospitals})



from django.contrib.auth.decorators import login_required
from django.shortcuts import render, redirect, get_object_or_404
from django.contrib import messages
from django.utils import timezone
from .models import BloodRequest, Organization


@login_required
def blood_managment(request, id):

    # ✅ id = Organization primary key
    organization = get_object_or_404(Organization, pk=id)

    # ✅ Get the linked auth user from organization
    receiver_user = organization.USER

    if request.method == 'POST':

        blood_group = request.POST.get('blood_group')
        units = request.POST.get('units')
        required_date = request.POST.get('required_date')

        required_date_obj = None

        # ✅ Date validation
        if required_date:
            required_date_obj = timezone.datetime.strptime(
                required_date, "%Y-%m-%d"
            ).date()

            today = timezone.now().date()

            if required_date_obj < today:
                messages.error(request, "Date cannot be in the past.")
                return redirect('blood_managment', id=id)

        # ✅ Create BloodRequest using linked USER
        BloodRequest.objects.create(
            sender=request.user,
            receiver=receiver_user,
            blood_group=blood_group,
            units=units,
            required_date=required_date_obj
        )

        messages.success(request, "Blood request sent successfully!")

        return redirect('my_blood_requests')

    return render(request, 'blood_managment.html', {
        'organization': organization
    })



@login_required
def my_blood_requests(request):

    requests = BloodRequest.objects.filter(
        sender=request.user
    ).select_related('receiver').order_by('-request_date')

    print("----- BLOOD REQUESTS DEBUG -----")

    for req in requests:
        print("Request ID:", req.id)
        print("Receiver User ID:", req.receiver.id)
        print("Receiver Username:", req.receiver.username)

        try:
            org = Organization.objects.get(USER=req.receiver)
            print(org)
            print("Organization Name:", org.organisation_name)
        except Organization.DoesNotExist:
            org = None
            print("Organization: Not Linked")

        print("Blood Group:", req.blood_group)
        print("Units:", req.units)
        print("Status:", req.status)
        print("-----------------------------")

    return render(request, 'my_blood_requests.html', {
        'requests': requests
    })



def organisation_managment(request):
    organisations = Organization.objects.get(id=request.session['organisations_id'])
    if request.method == 'POST':
        organisations.organisation_name = request.POST.get('organisation_name')
        organisations.category.category_name = request.POST.get('category.category_name')
        organisations.email = request.POST.get('email')
        organisations.phone = request.POST.get('phone')
        organisations.address = request.POST.get('address')
        organisations.save()
        return redirect('organisation_profilee')
    return render(request, 'organisation_managment.html', {'organisations': organisations})


def hospital_view_request_blood(request):
    organization=Organization.objects.filter(status='approved',category__category_name__iexact='blood_bank')
    return render(request,'blood_request.html',{'organization':organization})

def blood_users(request):
    return render(request,'blood_users.html')

def organisation_profilee(request):
    organisations = Organization.objects.get(id=request.session['organisations_id'])
    return render(request, 'organisation_profilee.html', {'organisations': organisations})

def accepted_users(request):
    return render(request,'accepted_users.html')



@login_required
def org_event(request):

    if request.method == "POST":

        title = request.POST.get("title")
        description = request.POST.get("description")
        event_date = request.POST.get("event_date")

        if event_date:
            event_date_obj = timezone.datetime.strptime(
                event_date, "%Y-%m-%d"
            ).date()

            today = timezone.now().date()

            # ❌ Prevent past date event creation
            if event_date_obj < today:
                messages.error(request, "You cannot add events on past dates.")
                return redirect("org_event")

        CalendarEvent.objects.create(
            ORGANIZATION=request.user,
            title=title,
            description=description,
            event_date=event_date
        )

        messages.success(request, "Event added successfully!")

        return redirect("org_event")

    return render(request, "org_event.html")



@login_required
def get_org_events(request):

    events = CalendarEvent.objects.filter(
        ORGANIZATION=request.user
    )

    data = []
    for event in events:
        data.append({
            "id": event.id,                     # ✅ IMPORTANT
            "title": event.title,
            "start": str(event.event_date),
            "description": event.description,
        })

    return JsonResponse(data, safe=False)



@login_required
def delete_event(request, id):

    if request.method == "POST":

        event = get_object_or_404(
            CalendarEvent,
            id=id,
            ORGANIZATION=request.user
        )

        event.delete()

        return JsonResponse({"status": "deleted"})

    return JsonResponse({"status": "invalid"}, status=400)

#
# @login_required
# def orgblood_request(request):
#
#     organization = get_object_or_404(Organization, USER=request.user)
#
#     requests = BloodRequest.objects.filter(
#         receiver=organization.USER
#     ).select_related('sender').order_by('-request_date')
#
#     if request.method == "POST":
#         request_id = request.POST.get("request_id")
#         action = request.POST.get("action")
#
#         blood_request = get_object_or_404(
#             BloodRequest,
#             id=request_id,
#             receiver=organization.USER
#         )
#
#         if action == "accept":
#
#             blood_request.status = "approved"
#             blood_request.accepted_date = timezone.now()
#             blood_request.save()
#
#             # -------- UPDATE USER PROFILE --------
#             profile = UserProfile.objects.get(USER=blood_request.sender)
#
#             # Convert safely from string to int
#             current_points = int(profile.reward_points)
#
#             # Add 100 points
#             current_points += 100
#             profile.reward_points = str(current_points)
#
#             # Set next request allowed date (70 days later)
#             profile.next_request_allowed_date = timezone.now().date() + timedelta(days=70)
#
#             profile.save()
#
#             messages.success(request, "Request Approved. 100 Points Added!")
#
#         elif action == "reject":
#             blood_request.status = "rejected"
#             blood_request.save()
#
#             messages.error(request, "Request Rejected")
#
#         return redirect("orgblood_request")
#
#     return render(request, 'orgblood_request.html', {
#         'requests': requests
#     })



@login_required
def orgblood_request(request):

    organization = get_object_or_404(Organization, USER=request.user)
    requests = BloodRequest.objects.filter(
        receiver=organization.USER
    ).select_related('sender').order_by('-request_date')

    if request.method == "POST":
        request_id = request.POST.get("request_id")
        action = request.POST.get("action")

        blood_request = get_object_or_404(
            BloodRequest,
            id=request_id,
            receiver=organization.USER
        )

        if action == "accept":
            blood_request.status = "approved"
            blood_request.accepted_date = timezone.now()
            blood_request.save()

            # -------- UPDATE USER PROFILE --------
            # profile = UserProfile.objects.get(USER=blood_request.sender)

            # # Convert safely from string to int
            # current_points = int(profile.reward_points)
            #
            # # Add 100 points
            # current_points += 100
            # profile.reward_points = str(current_points)
            #
            # # Set next request allowed date (70 days later)
            # profile.next_request_allowed_date = timezone.now().date() + timedelta(days=70)
            #
            # profile.save()

            messages.success(request, "Request Approved")

        elif action == "reject":
            blood_request.status = "rejected"
            blood_request.save()

            messages.error(request, "Request Rejected")

        return redirect("orgblood_request")

    return render(request, 'orgblood_request.html', {
        'requests': requests
    })


@login_required
def orgaccept_user(request):

    organization = get_object_or_404(Organization, USER=request.user)

    accepted_requests = BloodRequest.objects.filter(
        receiver=organization.USER,
        status='approved'
    ).select_related('sender').order_by('-accepted_date')

    return render(request, 'orgaccept_user.html', {
        'accepted_requests': accepted_requests
    })


@login_required
@csrf_exempt
@never_cache
def admin_view_approved_organizations(request):
    organizations = Organization.objects.filter(status='approved')
    return render(
        request,
        'admin_view_approved_organizations.html',
        {'organizations': organizations}
    )


@login_required
@csrf_exempt
@never_cache
def admin_view_registered_users(request):
    organizations = UserProfile.objects.all()
    return render(
        request,
        'admin_view_registered_users.html',
        {'organizations': organizations}
    )

@login_required
@csrf_exempt
@never_cache
def donation_activities(request):

    blood_requests = BloodRequest.objects.select_related(
        "sender", "receiver"
    ).filter(status="approved").order_by("-accepted_date")

    donations = []

    for d in blood_requests:
        if d.units:
            points = d.units * 50   # 50 points per unit
        else:
            points = 100           # default points

        donations.append({
            "id": d.id,
            "sender": d.sender.username,
            "receiver": d.receiver.username,
            "blood_group": d.blood_group,
            "units": d.units,
            "required_date": d.required_date,
            "accepted_date": d.accepted_date,
            "status": d.status,
            "points": points,
        })

    return render(
        request,
        "donation_activities.html",
        {"donations": donations}
    )

from django.shortcuts import redirect
from django.contrib.auth import logout as auth_logout
@never_cache
def logout_view(request):
    auth_logout(request)
    request.session.flush()

    response = redirect('login')
    response['Cache-Control'] = 'no-store, no-cache, must-revalidate, max-age=0'
    response['Pragma'] = 'no-cache'
    response['Expires'] = '0'

    return response

#////////////FLUTTER//////////////////////////////////////////////////////////////////////////////////////////////////



# ================= REGISTER =================
@csrf_exempt
def user_register(request):

    if request.method == 'POST':
        try:
            username = request.POST.get('username')
            password = request.POST.get('password')
            name = request.POST.get('name')
            email = request.POST.get('email')
            phone = request.POST.get('phone')
            blood_group = request.POST.get('blood_group')
            address = request.POST.get('address')
            profile_picture = request.FILES.get('profile_picture')

            if User.objects.filter(username=username).exists():
                return JsonResponse({
                    'status': 'error',
                    'error': 'Username already exists'
                })

            user = User.objects.create_user(
                username=username,
                password=password,email=email
            )

            UserProfile.objects.create(
                USER=user,
                name=name,
                email=email,
                phone=phone,
                blood_group=blood_group,
                address=address,
                profile_picture=profile_picture
            )

            return JsonResponse({'status': 'ok'})

        except Exception as e:
            return JsonResponse({
                'status': 'error',
                'error': str(e)
            })

    return JsonResponse({'status': 'invalid request'})


# ================= LOGIN =================
@csrf_exempt
def user_login(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)

            username = data['username']
            password = data['password']

            user = authenticate(username=username, password=password)

            if user is not None:

                profile = UserProfile.objects.get(USER=user)

                profile_pic = ""
                if profile.profile_picture:
                    profile_pic = request.build_absolute_uri(profile.profile_picture.url)

                return JsonResponse({
                    'status': 'ok',
                    'lid': user.id,                     # Auth User ID
                    'pid': profile.id,                  # Profile Primary Key
                    'username': user.username,
                    'name': profile.name,
                    'email': profile.email,
                    'profile_picture': profile_pic,
                    'reward_points': profile.reward_points,
                    'health_score': profile.health_score
                })
            else:
                return JsonResponse({
                    'status': 'error',
                    'error': 'Invalid username or password'
                })

        except Exception as e:
            return JsonResponse({
                'status': 'error',
                'error': str(e)
            })

    return JsonResponse({'status': 'invalid request'})



from django.views.decorators.csrf import csrf_exempt

#
# @csrf_exempt
# def user_profile(request):
#
#     if request.method == "POST":
#         try:
#             lid = request.POST.get("lid")
#             action = request.POST.get("action", "view")
#
#             user = User.objects.get(id=lid)
#             profile = UserProfile.objects.get(USER=user)
#
#             # ---------------- EDIT PROFILE ----------------
#             if action == "edit":
#
#                 profile.name = request.POST.get("name", profile.name)
#                 profile.email = request.POST.get("email", profile.email)
#                 profile.phone = request.POST.get("phone", profile.phone)
#                 profile.blood_group = request.POST.get("blood_group", profile.blood_group)
#                 profile.address = request.POST.get("address", profile.address)
#
#                 # -------- IMAGE UPDATE --------
#                 if "profile_picture" in request.FILES:
#                     profile.profile_picture = request.FILES["profile_picture"]
#
#                 profile.save()
#
#             # ---------------- RETURN ABSOLUTE IMAGE URL ----------------
#             image_url = ""
#             if profile.profile_picture:
#                 image_url = request.build_absolute_uri(
#                     profile.profile_picture.url
#                 )
#
#             return JsonResponse({
#                 "status": "ok",
#                 "lid": user.id,
#                 "username": user.username,
#                 "name": profile.name,
#                 "email": profile.email,
#                 "phone": profile.phone,
#                 "blood_group": profile.blood_group,
#                 "address": profile.address,
#                 "health_score": profile.health_score,
#                 "reward_points": profile.reward_points,
#                 "profile_picture": image_url,
#             })
#
#         except Exception as e:
#             return JsonResponse({
#                 "status": "error",
#                 "message": str(e)
#             })
#
#     return JsonResponse({
#         "status": "error",
#         "message": "Invalid request"
#     })
#

from django.utils import timezone

@csrf_exempt
def user_profile(request):

    if request.method == "POST":
        try:
            lid = request.POST.get("lid")
            action = request.POST.get("action", "view")

            user = User.objects.get(id=lid)
            profile = UserProfile.objects.get(USER=user)

            today = timezone.now().date()

            # ==================================================
            # ✅ SAFE REWARD DEDUCTION LOGIC
            # ==================================================
            if profile.next_request_allowed_date:

                allowed_date = profile.next_request_allowed_date

                if today > allowed_date:

                    # Determine last day we deducted
                    last_check_date = (
                        profile.last_penalty_date
                        if profile.last_penalty_date
                        else allowed_date
                    )

                    # Only deduct if today is after last deduction
                    if today > last_check_date:

                        days_to_deduct = (today - last_check_date).days

                        print("Days To Deduct:", days_to_deduct)

                        current_points = int(profile.reward_points)

                        new_points = current_points - days_to_deduct

                        if new_points < 0:
                            new_points = 0

                        print("Old Points:", current_points)
                        print("New Points:", new_points)

                        profile.reward_points = str(new_points)

                        # Update last penalty date to today
                        profile.last_penalty_date = today

                        profile.save()

            # ==================================================
            # ---------------- EDIT PROFILE ----------------
            # ==================================================
            if action == "edit":

                profile.name = request.POST.get("name", profile.name)
                profile.email = request.POST.get("email", profile.email)
                profile.phone = request.POST.get("phone", profile.phone)
                profile.blood_group = request.POST.get("blood_group", profile.blood_group)
                profile.address = request.POST.get("address", profile.address)

                if "profile_picture" in request.FILES:
                    profile.profile_picture = request.FILES["profile_picture"]

                profile.save()

            # ---------------- IMAGE URL ----------------
            image_url = ""
            if profile.profile_picture:
                image_url = request.build_absolute_uri(
                    profile.profile_picture.url
                )

            return JsonResponse({
                "status": "ok",
                "lid": user.id,
                "username": user.username,
                "name": profile.name,
                "email": profile.email,
                "phone": profile.phone,
                "blood_group": profile.blood_group,
                "address": profile.address,
                "health_score": profile.health_score,
                "reward_points": profile.reward_points,
                "profile_picture": image_url,
                "next_request_allowed_date":
                    str(profile.next_request_allowed_date)
                    if profile.next_request_allowed_date else None
            })

        except Exception as e:
            print("ERROR:", str(e))
            return JsonResponse({
                "status": "error",
                "message": str(e)
            })

    return JsonResponse({
        "status": "error",
        "message": "Invalid request"
    })


from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
import json
from .models import User, UserProfile, BloodRequest

@csrf_exempt
def incoming_request(request):
    if request.method != "POST":
        return JsonResponse({"status": "error", "message": "Invalid request method"}, status=405)

    try:
        data = json.loads(request.body.decode("utf-8"))
        lid = data.get("lid")

        if not lid:
            return JsonResponse({"status": "error", "message": "Missing user id"}, status=400)

        try:
            user = User.objects.get(id=lid)
        except User.DoesNotExist:
            return JsonResponse({"status": "error", "message": "User not found"}, status=404)

        requests = BloodRequest.objects.filter(receiver=user)

        incoming_data = []
        for req in requests:
            try:
                sender_profile = UserProfile.objects.get(USER=req.sender)
                incoming_data.append({
                    "request_id": req.id,
                    "status": req.status,  # important for Flutter to show Chat button
                    "blood_group": req.blood_group,
                    "request_date": req.request_date.isoformat() if req.request_date else None,
                    "accepted_date": req.accepted_date.isoformat() if req.accepted_date else None,
                    "sender_id": req.sender.id,
                    "sender_username": req.sender.username,
                    "name": sender_profile.name,
                    "email": sender_profile.email,
                    "phone": sender_profile.phone,
                    "address": sender_profile.address,
                    "health_score": sender_profile.health_score,
                    "reward_points": sender_profile.reward_points,
                    "sender_blood_group": sender_profile.blood_group,
                })
            except UserProfile.DoesNotExist:
                continue

        return JsonResponse({
            "status": "ok",
            "incoming_requests": incoming_data
        }, safe=False)

    except json.JSONDecodeError:
        return JsonResponse({"status": "error", "message": "Invalid JSON"}, status=400)
    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)}, status=500)

@csrf_exempt
def donor_list(request):
    if request.method == "POST":
        try:
            data = json.loads(request.body.decode("utf-8"))
            lid = int(data.get("lid"))

            print("Received lid:", lid)

            profiles = UserProfile.objects.exclude(USER_id=lid)

            donor_data = []
            for profile in profiles:
                donor_data.append({
                    "id": profile.USER.id,
                    "name": profile.name,
                    "email": profile.email,
                    "phone": profile.phone,
                    "blood_group": profile.blood_group,
                    "address": profile.address,
                    "reward_points": profile.reward_points,
                    "health_score": profile.health_score,
                })

            return JsonResponse({
                "status": "ok",
                "profiles": donor_data
            })

        except Exception as e:
            print("Error in donor_list:", str(e))
            return JsonResponse({
                "status": "error",
                "message": str(e)
            })

    return JsonResponse({
        "status": "error",
        "message": "Invalid request"
    })

@csrf_exempt
def update_request_status(request):
    if request.method == "POST":
        try:
            data = json.loads(request.body.decode("utf-8"))

            request_id = data.get("request_id")
            action = data.get("status")   # "accepted" or "rejected"

            if not request_id or not action:
                return JsonResponse({
                    "status": "error",
                    "message": "Missing request_id or status"
                }, status=400)

            try:
                blood_request = BloodRequest.objects.get(id=request_id)
            except BloodRequest.DoesNotExist:
                return JsonResponse({
                    "status": "error",
                    "message": "Request not found"
                }, status=404)

            # Only allow valid actions
            if action not in ["accepted", "rejected"]:
                return JsonResponse({
                    "status": "error",
                    "message": "Invalid status value"
                }, status=400)

            # Update status
            blood_request.status = action

            # If accepted, store accepted date
            if action == "accepted":
                blood_request.accepted_date = timezone.now()

            blood_request.save()

            return JsonResponse({
                "status": "ok",
                "message": f"Request {action} successfully"
            })

        except json.JSONDecodeError:
            return JsonResponse({
                "status": "error",
                "message": "Invalid JSON"
            }, status=400)

        except Exception as e:
            print("UPDATE REQUEST STATUS ERROR:", e)
            return JsonResponse({
                "status": "error",
                "message": str(e)
            }, status=500)

    return JsonResponse({
        "status": "error",
        "message": "Invalid request method"
    }, status=405)


@csrf_exempt
def send_request(request):
    try:
        if request.method != "POST":
            return JsonResponse({
                "status": "error",
                "message": "Only POST method allowed"
            })

        data = json.loads(request.body.decode("utf-8"))

        sender_id = int(data.get("sender_id"))
        receiver_id = int(data.get("receiver_id"))
        blood_group = data.get("blood_group")

        print("Sender:", sender_id)
        print("Receiver:", receiver_id)
        print("Blood group:", blood_group)

        if not blood_group:
            return JsonResponse({
                "status": "error",
                "message": "Blood group missing"
            })

        sender = User.objects.get(id=sender_id)
        receiver = User.objects.get(id=receiver_id)

        blood_request = BloodRequest.objects.create(
            sender=sender,
            receiver=receiver,
            blood_group=blood_group,
            status="pending",
            request_date=timezone.now()
        )

        return JsonResponse({
            "status": "ok",
            "message": "Blood request sent successfully",
            "request_id": blood_request.id
        })

    except User.DoesNotExist:
        return JsonResponse({
            "status": "error",
            "message": "Invalid user ID"
        })

    except Exception as e:
        print("SEND REQUEST ERROR:", e)
        return JsonResponse({
            "status": "error",
            "message": str(e)
        })


# @csrf_exempt
# def chatbot_response(request):
#     if request.method != "POST":
#         return JsonResponse({"error": "POST only"}, status=405)
#
#     try:
#         body = json.loads(request.body)
#         user_id = body.get("lid")
#         user_message = body.get("message")
#
#         user = User.objects.get(id=user_id)
#         profile = UserProfile.objects.get(USER=user)
#         vitals = HealthVitals.objects.filter(USER=user).last()
#
#
#         system_prompt = f"""
# You are a professional AI health assistant.
#
# USER DETAILS:
# Name: {profile.name}
# Age: Not provided
# Blood Group: {profile.blood_group}
# Health Score: {profile.health_score}
# Reward Points: {profile.reward_points}
#
# LATEST HEALTH VITALS:
# Hemoglobin: {vitals.hemoglobin if vitals else "N/A"}
# Blood Pressure: {vitals.blood_pressure if vitals else "N/A"}
# Sugar Level: {vitals.sugar_level if vitals else "N/A"}
# Weight: {vitals.weight if vitals else "N/A"}
#
# RULES:
# - Give medical guidance, not diagnosis
# - Be polite, friendly, and concise
# - Suggest doctor visit when values are abnormal
# """
#
#         model = genai.GenerativeModel("gemini-2.5-flash")
#
#         response = model.generate_content(
#             f"{system_prompt}\n\nUSER QUESTION: {user_message}"
#         )
#
#         return JsonResponse({
#             "status": "ok",
#             "reply": response.text
#         })
#
#     except Exception as e:
#         return JsonResponse({
#             "status": "error",
#             "error": str(e)
#         }, status=500)



from django.views.decorators.csrf import csrf_exempt
from django.http import JsonResponse
from django.contrib.auth.models import User
from .models import UserProfile, HealthVitals, ChatMessage
import json
import google.generativeai as genai


@csrf_exempt
def chatbot_response(request):
    if request.method != "POST":
        return JsonResponse({"error": "POST only"}, status=405)

    try:
        body = json.loads(request.body)
        user_id = body.get("lid")
        user_message = body.get("message")

        user = User.objects.get(id=user_id)
        profile = UserProfile.objects.get(USER=user)
        vitals = HealthVitals.objects.filter(USER=user).last()

        # ✅ Save USER message first
        ChatMessage.objects.create(
            USER=user,
            role="user",
            message=user_message
        )

        # ✅ Get last 10 chat messages for memory
        last_messages = ChatMessage.objects.filter(USER=user).order_by('-created_at')[:10]
        last_messages = reversed(last_messages)

        history_text = ""
        for msg in last_messages:
            history_text += f"{msg.role.upper()}: {msg.message}\n"

        # ✅ System Prompt
        system_prompt = f"""
You are a professional AI health assistant.

USER DETAILS:
Name: {profile.name}
Blood Group: {profile.blood_group}
Health Score: {profile.health_score}
Reward Points: {profile.reward_points}

LATEST HEALTH VITALS:
Hemoglobin: {vitals.hemoglobin if vitals else "N/A"}
Blood Pressure: {vitals.blood_pressure if vitals else "N/A"}
Sugar Level: {vitals.sugar_level if vitals else "N/A"}
Weight: {vitals.weight if vitals else "N/A"}

CONVERSATION HISTORY:
{history_text}

RULES:
- Give guidance, not diagnosis
- Be polite, friendly, concise
- Suggest doctor visit if abnormal
"""

        model = genai.GenerativeModel("gemini-2.5-flash")

        response = model.generate_content(
            f"{system_prompt}\n\nUSER QUESTION: {user_message}"
        )

        bot_reply = response.text

        # ✅ Save BOT reply
        ChatMessage.objects.create(
            USER=user,
            role="bot",
            message=bot_reply
        )

        return JsonResponse({
            "status": "ok",
            "reply": bot_reply
        })

    except Exception as e:
        return JsonResponse({
            "status": "error",
            "error": str(e)
        }, status=500)


@csrf_exempt
def get_chat_history(request):
    user_id = request.GET.get("lid")

    try:
        user = User.objects.get(id=user_id)
        messages = ChatMessage.objects.filter(USER=user)

        data = []
        for msg in messages:
            data.append({
                "role": msg.role,
                "text": msg.message
            })

        return JsonResponse({"status": "ok", "messages": data})

    except:
        return JsonResponse({"status": "error"})


@csrf_exempt
def user_requested_users(request):
    if request.method != "POST":
        return JsonResponse({"status": "error", "message": "POST only"})

    try:
        body = json.loads(request.body.decode("utf-8"))
        lid = body.get("lid")

        if not lid:
            return JsonResponse({"status": "error", "message": "Missing user id"})

        requests = BloodRequest.objects.filter(sender_id=lid)

        result = []

        for r in requests:
            try:

                user = User.objects.get(id=r.receiver_id)
                profile = UserProfile.objects.get(USER=user)

                result.append({
                    "id": str(user.id),
                    "name": profile.name,
                    "blood_group": profile.blood_group,
                    "phone": profile.phone,
                    "email": profile.email,
                    "request_status": "accepted" if r.status == "approved" else r.status,  # approved -> accepted
                })
            except Exception as e:
                print("User fetch error:", e)
                continue

        return JsonResponse({
            "status": "ok",
            "requested_users": result
        })

    except Exception as e:
        print("Requested Users API Error:", e)
        return JsonResponse({"status": "error", "message": str(e)})


@login_required
def org_chat(request, id):

    receiver = get_object_or_404(User, id=id)

    # Fetch conversation
    chats = Chat.objects.filter(
        SENDER__in=[request.user, receiver],
        RECEIVER__in=[request.user, receiver]
    ).order_by('id')

    if request.method == "POST":
        message = request.POST.get("message")

        if message:
            Chat.objects.create(
                SENDER=request.user,
                RECEIVER=receiver,
                message=message,
                date_time=str(timezone.now())
            )

        return redirect('org_chat', id=id)

    return render(request, 'org_chat.html', {
        'receiver': receiver,
        'chats': chats
    })


@login_required
def get_org_chat_messages(request, id):
    receiver = get_object_or_404(User, id=id)

    chats = Chat.objects.filter(
        SENDER__in=[request.user, receiver],
        RECEIVER__in=[request.user, receiver]
    ).order_by('id')

    data = []

    for chat in chats:

        if isinstance(chat.date_time, str):
            try:
                dt = datetime.fromisoformat(chat.date_time)
            except:
                dt = timezone.now()
        else:
            dt = chat.date_time

        data.append({
            "sender_id": chat.SENDER.id,
            "message": chat.message,
            "time": dt.strftime("%d %b %Y, %I:%M %p")
        })

    return JsonResponse({"chats": data})

@csrf_exempt
def get_calendar_events(request):
    if request.method == "GET":
        events = CalendarEvent.objects.all()

        event_list = []

        for event in events:

            # Only approved organisations
            try:
                org = Organization.objects.get(USER=event.ORGANIZATION)
                if org.status != "approved":
                    continue
            except:
                continue

            event_list.append({
                "title": event.title,
                "description": event.description,
                "event_date": event.event_date,
                "organization": org.organisation_name,
            })

        return JsonResponse({
            "status": "ok",
            "events": event_list
        })

    return JsonResponse({"status": "error"})



from django.views.decorators.csrf import csrf_exempt



import json
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.utils import timezone
from django.contrib.auth.models import User
from .models import Organization, UserProfile


@csrf_exempt
def view_blood_banks(request):

    print("\n========== VIEW BLOOD BANKS API CALLED ==========")

    if request.method == "POST":

        try:
            data = json.loads(request.body)
            sender_id = data.get("sender_id")

            print("Sender ID Received:", sender_id)

            if not sender_id:
                return JsonResponse({
                    "status": "error",
                    "message": "Sender ID required"
                })

            # --------------------------------------------------
            # GET USER & PROFILE
            # --------------------------------------------------
            sender = User.objects.get(id=sender_id)
            print("Sender Username:", sender.username)

            profile = UserProfile.objects.get(USER=sender)

            print("Current Reward Points:", profile.reward_points)
            print("Next Request Allowed Date:", profile.next_request_allowed_date)

            today = timezone.now().date()
            print("Today Date:", today)

            # --------------------------------------------------
            # COOLDOWN CHECK
            # --------------------------------------------------
            can_send = True
            next_allowed_date = None

            if profile.next_request_allowed_date:

                if today < profile.next_request_allowed_date:
                    can_send = False
                    next_allowed_date = profile.next_request_allowed_date
                    print("Cooldown Active Until:",
                          profile.next_request_allowed_date)
                else:
                    print("Cooldown Passed → Can Send")

            else:
                print("No Cooldown Set → Can Send")

            # FETCH APPROVED BLOOD BANKS

            blood_banks = Organization.objects.filter(
             status="approved"
                ).exclude(
            category__category_name__iexact="blood_bank"
              )

            print("Total Blood Banks Found:", blood_banks.count())

            data_list = []

            for org in blood_banks:
                print("-----------------------------------")
                print("Organization ID:", org.id)
                print("Organization Name:", org.organisation_name)
                print("Email:", org.email)
                print("Phone:", org.phone)
                print("-----------------------------------")

                data_list.append({
                    "organization_id": org.id,
                    "organisation_name": org.organisation_name,
                    "email": org.email,
                    "phone": org.phone,
                    "address": org.address,
                })

            print("========== API SUCCESS ==========\n")

            return JsonResponse({
                "status": "ok",
                "can_send_request": can_send,
                "next_allowed_date": str(next_allowed_date) if next_allowed_date else None,
                "organizations": data_list
            })

        except User.DoesNotExist:
            print("User Not Found")
            return JsonResponse({
                "status": "error",
                "message": "User not found"
            })

        except UserProfile.DoesNotExist:
            print("UserProfile Not Found")
            return JsonResponse({
                "status": "error",
                "message": "User profile not found"
            })

        except Exception as e:
            print("ERROR OCCURRED:", str(e))
            return JsonResponse({
                "status": "error",
                "message": str(e)
            })

    print("Invalid Request Method:", request.method)

    return JsonResponse({
        "status": "error",
        "message": "Invalid request"
    })




@csrf_exempt
def send_blood_request(request):

    if request.method == "POST":
        try:
            data = json.loads(request.body)

            sender_id = data.get("sender_id")
            organization_id = data.get("organization_id")
            blood_group = data.get("blood_group")
            units = data.get("units")
            time_str = data.get("time")  # ✅ NEW
            required_date = data.get("required_date")

            # ================= VALIDATION =================
            if not all([sender_id, organization_id, blood_group, units, time_str, required_date]):
                return JsonResponse({
                    "status": "error",
                    "message": "All fields are required"
                })

            # Convert units safely
            try:
                units = int(units)
            except:
                return JsonResponse({
                    "status": "error",
                    "message": "Units must be a number"
                })

            # Parse required_date
            try:
                required_date = datetime.strptime(required_date, "%Y-%m-%d").date()
            except:
                return JsonResponse({
                    "status": "error",
                    "message": "Invalid date format"
                })

            # Parse time (AM/PM format)
            try:
                parsed_time = datetime.strptime(time_str, "%I:%M %p").time()
            except:
                return JsonResponse({
                    "status": "error",
                    "message": "Invalid time format"
                })

            # ================= FETCH USER & ORG =================
            sender = User.objects.get(id=sender_id)
            organization = Organization.objects.get(id=organization_id)
            receiver = organization.USER

            profile = UserProfile.objects.get(USER=sender)

            today = timezone.now().date()

            # ================= COOLDOWN LOGIC =================

            if profile.next_request_allowed_date is not None:
                if today < profile.next_request_allowed_date:
                    return JsonResponse({
                        "status": "error",
                        "message": f"You can send next request after {profile.next_request_allowed_date}"
                    })

            # ================= CREATE BLOOD REQUEST =================

            BloodRequest.objects.create(
                sender=sender,
                receiver=receiver,
                blood_group=blood_group,
                units=units,
                time=parsed_time,
                required_date=required_date,
                status="pending"
            )

            return JsonResponse({
                "status": "ok",
                "message": "Blood request sent successfully"
            })

        except User.DoesNotExist:
            return JsonResponse({
                "status": "error",
                "message": "User not found"
            })

        except Organization.DoesNotExist:
            return JsonResponse({
                "status": "error",
                "message": "Organization not found"
            })

        except UserProfile.DoesNotExist:
            return JsonResponse({
                "status": "error",
                "message": "User profile not found"
            })

        except Exception as e:
            return JsonResponse({
                "status": "error",
                "message": str(e)
            })

    return JsonResponse({
        "status": "error",
        "message": "Invalid request method"
    })



from django.contrib.auth.decorators import login_required
from django.shortcuts import render, redirect



@login_required
def user_chat(request, user_id):

    sender = request.user
    receiver = User.objects.get(id=user_id)

    print("Logged User:", sender.username)
    print("Chat With:", receiver.username)

    # -------- SEND MESSAGE --------
    if request.method == "POST":
        message = request.POST.get("message")

        if message:
            Chat.objects.create(
                SENDER=sender,
                RECEIVER=receiver,
                message=message,
                date_time=str(datetime.now())
            )
            print("Message Saved")

    # -------- FETCH CHAT --------
    messages_list = Chat.objects.filter(
        SENDER__in=[sender, receiver],
        RECEIVER__in=[sender, receiver]
    ).order_by("id")

    return render(request, "user_chat.html", {
        "messages": messages_list,
        "receiver": receiver
    })
#
# from django.http import JsonResponse
# from django.views.decorators.csrf import csrf_exempt
# from django.contrib.auth.models import User
# from django.utils import timezone
# from .models import BloodRequest, Organization, UserProfile
# import json
#
#
# @csrf_exempt
# def view_my_requests(request):
#
#     if request.method != "POST":
#         return JsonResponse({
#             "status": "error",
#             "message": "Invalid request"
#         })
#
#     try:
#         data = json.loads(request.body)
#         user_id = data.get("user_id")
#
#         if not user_id:
#             return JsonResponse({
#                 "status": "error",
#                 "message": "User ID required"
#             })
#
#         user_id = int(user_id)
#
#         # 🔥 Get all requests sent by user
#         requests = BloodRequest.objects.filter(
#             sender_id=user_id
#         ).select_related("receiver").order_by("-request_date")
#
#         response_data = []
#
#         print("\n========== USER REQUESTS ==========")
#
#         for req in requests:
#
#             receiver_user = req.receiver
#             receiver_type = "user"
#             receiver_name = ""
#             receiver_phone = ""
#
#             # ---------------- CHECK IF ORGANIZATION ----------------
#             try:
#                 org = Organization.objects.get(USER=receiver_user)
#                 receiver_type = "organization"
#                 receiver_name = org.organisation_name
#                 receiver_phone = org.phone
#             except Organization.DoesNotExist:
#
#                 # ---------------- ELSE NORMAL USER ----------------
#                 try:
#                     profile = UserProfile.objects.get(USER=receiver_user)
#                     receiver_name = profile.name
#                     receiver_phone = profile.phone
#                 except UserProfile.DoesNotExist:
#                     receiver_name = receiver_user.username
#
#             print("Request ID:", req.id)
#             print("Receiver:", receiver_name)
#             print("Type:", receiver_type)
#             print("Status:", req.status)
#             print("--------------------------------")
#
#             response_data.append({
#                 "request_id": req.id,
#                 "receiver_id": receiver_user.id,
#                 "receiver_name": receiver_name,
#                 "receiver_phone": receiver_phone,
#                 "receiver_type": receiver_type,
#                 "blood_group": req.blood_group,
#                 "units": req.units,
#                 "required_date": str(req.required_date) if req.required_date else "",
#                 "status": req.status,
#                 "request_date": req.request_date.strftime("%d-%m-%Y %H:%M"),
#                 "accepted_date": req.accepted_date.strftime("%d-%m-%Y %H:%M") if req.accepted_date else ""
#             })
#
#         print("========== END ==========\n")
#
#         return JsonResponse({
#             "status": "ok",
#             "requests": response_data
#         })
#
#     except Exception as e:
#         print("ERROR:", str(e))
#         return JsonResponse({
#             "status": "error",
#             "message": str(e)
#         })





from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth.models import User
from django.db.models import Q
from .models import BloodRequest, Organization, UserProfile
import json


@csrf_exempt
def view_my_requests(request):

    print("\n========== VIEW MY REQUESTS API CALLED ==========")

    if request.method != "POST":
        print("❌ Not POST request")
        return JsonResponse({
            "status": "error",
            "message": "POST request required"
        })

    try:
        print("Raw Body:", request.body)

        data = json.loads(request.body)
        print("Decoded Data:", data)

        user_id = data.get("user_id")

        if not user_id:
            print("❌ User ID missing")
            return JsonResponse({
                "status": "error",
                "message": "User ID required"
            })

        user_id = int(user_id)
        print("User ID:", user_id)

        # 🔥 Fetch all requests sent by this user
        requests = BloodRequest.objects.filter(
            sender_id=user_id
        ).select_related("receiver").order_by("-request_date")

        print("Total Requests Found:", requests.count())

        response_data = []

        for req in requests:

            receiver_user = req.receiver
            receiver_type = "user"
            receiver_name = ""
            receiver_phone = ""

            # ================= CHECK ORGANIZATION =================
            try:
                org = Organization.objects.get(USER=receiver_user)
                receiver_type = "organization"
                receiver_name = org.organisation_name
                receiver_phone = org.phone

                print("Receiver is ORGANIZATION:",
                      receiver_name)

            except Organization.DoesNotExist:

                # ================= NORMAL USER =================
                try:
                    profile = UserProfile.objects.get(
                        USER=receiver_user
                    )
                    receiver_name = profile.name
                    receiver_phone = profile.phone

                    print("Receiver is USER:",
                          receiver_name)

                except UserProfile.DoesNotExist:
                    receiver_name = receiver_user.username
                    print("Receiver fallback username:",
                          receiver_name)

            print("--------------------------------")
            print("Request ID:", req.id)
            print("Blood Group:", req.blood_group)
            print("Units:", req.units)
            print("Status:", req.status)
            print("--------------------------------")

            response_data.append({
                "request_id": req.id,

                # 🔥 VERY IMPORTANT FOR CHAT
                "receiver_id": receiver_user.id,
                "receiver_name": receiver_name,
                "receiver_phone": receiver_phone,
                "receiver_type": receiver_type,

                "blood_group": req.blood_group,
                "units": req.units,

                "required_date":
                    str(req.required_date)
                    if req.required_date else "",

                "status": req.status,

                "request_date":
                    req.request_date.strftime("%d-%m-%Y %H:%M")
                    if req.request_date else "",

                "accepted_date":
                    req.accepted_date.strftime("%d-%m-%Y %H:%M")
                    if req.accepted_date else ""
            })

        print("========== END ==========\n")

        return JsonResponse({
            "status": "ok",
            "total_requests": len(response_data),
            "requests": response_data
        })

    except Exception as e:
        print("❌ Exception:", str(e))
        return JsonResponse({
            "status": "error",
            "message": str(e)
        })

from .models import Chat
import json
from django.views.decorators.csrf import csrf_exempt



# ================= FETCH CHAT =================
@csrf_exempt
def user_chat_messages(request):

    if request.method == "POST":
        try:
            data = json.loads(request.body)
            sender_id = data.get("sender_id")
            receiver_id = data.get("receiver_id")

            messages = Chat.objects.filter(
                SENDER__in=[sender_id, receiver_id],
                RECEIVER__in=[sender_id, receiver_id]
            ).order_by("id")

            chat_list = []

            for msg in messages:
                chat_list.append({
                    "message": msg.message,
                    "sender_id": msg.SENDER.id,
                    "date_time": msg.date_time
                })

            return JsonResponse({
                "status": "ok",
                "messages": chat_list
            })

        except Exception as e:
            return JsonResponse({
                "status": "error",
                "message": str(e)
            })

    return JsonResponse({"status": "error"})

@csrf_exempt
def user_send_message(request):

    if request.method == "POST":
        try:
            data = json.loads(request.body)

            sender_id = data.get("sender_id")
            receiver_id = data.get("receiver_id")
            message = data.get("message")

            sender = User.objects.get(id=sender_id)
            receiver = User.objects.get(id=receiver_id)

            Chat.objects.create(
                SENDER=sender,
                RECEIVER=receiver,
                message=message,
                date_time=str(timezone.now())
            )

            return JsonResponse({
                "status": "ok",
                "message": "Message Sent"
            })

        except Exception as e:
            return JsonResponse({
                "status": "error",
                "message": str(e)
            })

    return JsonResponse({"status": "error"})

#
# from django.http import JsonResponse
# from django.views.decorators.csrf import csrf_exempt
# from django.utils import timezone
# from django.contrib.auth.models import User
# from datetime import datetime, timedelta
# from .models import BloodRequest, UserProfile
# import json
#
#
# @csrf_exempt
# def view_matching_users(request):
#
#     print("\n========== VIEW MATCHING USERS API CALLED ==========")
#
#     if request.method != "POST":
#         return JsonResponse({
#             "status": "error",
#             "message": "Invalid request"
#         }, status=405)
#
#     try:
#         data = json.loads(request.body)
#         user_id = data.get("user_id")
#
#         if not user_id:
#             return JsonResponse({
#                 "status": "error",
#                 "message": "User ID required"
#             }, status=400)
#
#         current_user = User.objects.get(id=int(user_id))
#         current_profile = UserProfile.objects.get(USER=current_user)
#
#         today = timezone.now().date()
#
#         # ✅ CHECK SENDER ELIGIBILITY
#         sender_next_date = current_profile.next_request_allowed_date
#
#         can_send_request = (
#             sender_next_date is None or
#             sender_next_date <= today
#         )
#
#         print("Sender Can Send Request:", can_send_request)
#
#         all_profiles = UserProfile.objects.exclude(USER=current_user)
#
#         matching_eligible = []
#         matching_not_eligible = []
#         other_eligible = []
#         other_not_eligible = []
#
#         for profile in all_profiles:
#
#             image_url = ""
#             if profile.profile_picture:
#                 image_url = request.build_absolute_uri(
#                     profile.profile_picture.url
#                 )
#
#             is_eligible = (
#                 profile.next_request_allowed_date is None or
#                 profile.next_request_allowed_date <= today
#             )
#
#             is_matching = (
#                 profile.blood_group.strip().upper() ==
#                 current_profile.blood_group.strip().upper()
#             )
#
#             user_data = {
#                 "user_id": profile.USER.id,
#                 "name": profile.name,
#                 "phone": profile.phone,
#                 "address": profile.address,
#                 "blood_group": profile.blood_group,
#                 "profile_picture": image_url,
#                 "eligible": is_eligible,
#                 "next_request_allowed_date":
#                     str(profile.next_request_allowed_date)
#                     if profile.next_request_allowed_date else None
#             }
#
#             if is_matching:
#                 if is_eligible:
#                     matching_eligible.append(user_data)
#                 else:
#                     matching_not_eligible.append(user_data)
#             else:
#                 if is_eligible:
#                     other_eligible.append(user_data)
#                 else:
#                     other_not_eligible.append(user_data)
#
#         print("========== END ==========\n")
#
#         return JsonResponse({
#             "status": "ok",
#
#             # 🔥 ADD THIS
#             "sender_can_send_request": can_send_request,
#             "sender_next_request_allowed_date":
#                 str(sender_next_date) if sender_next_date else None,
#
#             "matching": {
#                 "eligible": matching_eligible,
#                 "not_eligible": matching_not_eligible
#             },
#             "others": {
#                 "eligible": other_eligible,
#                 "not_eligible": other_not_eligible
#             }
#         }, status=200)
#
#     except Exception as e:
#         print("ERROR:", str(e))
#         return JsonResponse({
#             "status": "error",
#             "message": "Something went wrong"
#         }, status=500)
#
#
# # ============================================================
# #                 SEND USER BLOOD REQUEST
# # ============================================================
# @csrf_exempt
# def send_user_blood_request(request):
#
#     print("\n========== SEND USER REQUEST API ==========")
#
#     if request.method != "POST":
#         return JsonResponse({
#             "status": "error",
#             "message": "Invalid request"
#         }, status=405)
#
#     try:
#         data = json.loads(request.body)
#
#         sender_id = data.get("sender_id")
#         receiver_id = data.get("receiver_id")
#         blood_group = data.get("blood_group")
#         units = data.get("units")
#         required_date = data.get("required_date")
#
#         # ---------------- VALIDATION ----------------
#         if not all([sender_id, receiver_id, blood_group, units, required_date]):
#             return JsonResponse({
#                 "status": "error",
#                 "message": "All fields required"
#             }, status=400)
#
#         sender = User.objects.get(id=int(sender_id))
#         receiver = User.objects.get(id=int(receiver_id))
#
#         if sender == receiver:
#             return JsonResponse({
#                 "status": "error",
#                 "message": "You cannot send request to yourself"
#             }, status=400)
#
#         sender_profile = UserProfile.objects.get(USER=sender)
#         today = timezone.now().date()
#
#         # ---------------- COOLDOWN CHECK ----------------
#         if sender_profile.next_request_allowed_date:
#             if today < sender_profile.next_request_allowed_date:
#                 return JsonResponse({
#                     "status": "error",
#                     "message":
#                         f"You can send next request after "
#                         f"{sender_profile.next_request_allowed_date}"
#                 }, status=400)
#
#         # ---------------- DUPLICATE PENDING CHECK ----------------
#         if BloodRequest.objects.filter(
#                 sender=sender,
#                 receiver=receiver,
#                 status="pending"
#         ).exists():
#             return JsonResponse({
#                 "status": "error",
#                 "message": "You already have a pending request"
#             }, status=400)
#
#         # ---------------- DATE VALIDATION ----------------
#         required_date_obj = datetime.strptime(
#             required_date, "%Y-%m-%d"
#         ).date()
#
#         if required_date_obj < today:
#             return JsonResponse({
#                 "status": "error",
#                 "message": "Required date cannot be in past"
#             }, status=400)
#
#         # ---------------- CREATE REQUEST ----------------
#         BloodRequest.objects.create(
#             sender=sender,
#             receiver=receiver,
#             blood_group=blood_group,
#             units=int(units),
#             required_date=required_date_obj,
#             status="pending"
#         )
#
#         print("Request Created Successfully")
#
#         return JsonResponse({
#             "status": "ok",
#             "message": "Blood request sent successfully"
#         }, status=201)
#
#     except User.DoesNotExist:
#         return JsonResponse({
#             "status": "error",
#             "message": "User not found"
#         }, status=404)
#
#     except UserProfile.DoesNotExist:
#         return JsonResponse({
#             "status": "error",
#             "message": "Profile not found"
#         }, status=404)
#
#     except Exception as e:
#         print("ERROR:", str(e))
#         return JsonResponse({
#             "status": "error",
#             "message": "Something went wrong"
#         }, status=500)
#
#
# from django.http import JsonResponse
# from django.views.decorators.csrf import csrf_exempt
# from django.contrib.auth.models import User
# from django.utils import timezone
# from .models import BloodRequest, UserProfile
# import json
#
#
# @csrf_exempt
# def view_received_requests(request):
#
#     print("\n========== VIEW RECEIVED REQUESTS ==========")
#
#     if request.method != "POST":
#         return JsonResponse({
#             "status": "error",
#             "message": "Invalid request"
#         })
#
#     try:
#         data = json.loads(request.body)
#         user_id = data.get("user_id")
#
#         if not user_id:
#             return JsonResponse({
#                 "status": "error",
#                 "message": "User ID required"
#             })
#
#         user = User.objects.get(id=int(user_id))
#
#         # Requests where logged user is receiver
#         requests = BloodRequest.objects.filter(
#             receiver=user
#         ).select_related("sender").order_by("-request_date")
#
#         response_data = []
#
#         for req in requests:
#
#             # Sender Profile
#             try:
#                 sender_profile = UserProfile.objects.get(
#                     USER=req.sender
#                 )
#                 sender_name = sender_profile.name
#             except UserProfile.DoesNotExist:
#                 sender_name = req.sender.username
#
#             response_data.append({
#                 "request_id": req.id,
#                 "sender_id": req.sender.id,
#                 "sender_name": sender_name,
#                 "blood_group": req.blood_group,
#                 "units": req.units,
#                 "required_date":
#                     str(req.required_date)
#                     if req.required_date else "",
#                 "status": req.status,
#                 "request_date":
#                     req.request_date.strftime(
#                         "%d-%m-%Y %H:%M"),
#                 "accepted_date":
#                     req.accepted_date.strftime(
#                         "%d-%m-%Y %H:%M")
#                     if req.accepted_date else ""
#             })
#
#         return JsonResponse({
#             "status": "ok",
#             "requests": response_data
#         })
#
#     except User.DoesNotExist:
#         return JsonResponse({
#             "status": "error",
#             "message": "User not found"
#         })
#
#     except Exception as e:
#         print("ERROR:", str(e))
#         return JsonResponse({
#             "status": "error",
#             "message": str(e)
#         })
#
#
# from django.utils import timezone
# from datetime import timedelta
# from django.db import transaction
# import json
# from django.http import JsonResponse
# from django.views.decorators.csrf import csrf_exempt
#
#
# @csrf_exempt
# def update_received_request_status(request):
#
#     print("\n========== UPDATE RECEIVED REQUEST STATUS ==========")
#
#     if request.method != "POST":
#         print("Invalid request method:", request.method)
#         return JsonResponse({
#             "status": "error",
#             "message": "Invalid request"
#         })
#
#     try:
#         data = json.loads(request.body)
#         print("Incoming Data:", data)
#
#         request_id = data.get("request_id")
#         action = data.get("action")  # approve / reject
#
#         print("Request ID:", request_id)
#         print("Action:", action)
#
#         if not request_id or not action:
#             print("Missing data")
#             return JsonResponse({
#                 "status": "error",
#                 "message": "Missing data"
#             })
#
#         with transaction.atomic():
#
#             blood_request = BloodRequest.objects.select_related(
#                 "receiver"
#             ).get(id=int(request_id))
#
#             print("Blood Request Found")
#             print("Current Status:", blood_request.status)
#             print("Receiver ID:", blood_request.receiver.id)
#
#             # Prevent double processing
#             if blood_request.status != "pending":
#                 print("Already processed")
#                 return JsonResponse({
#                     "status": "error",
#                     "message": "Already processed"
#                 })
#
#             # ================= APPROVE =================
#             if action == "approve":
#
#                 print("Approving request...")
#
#                 blood_request.status = "approved"
#                 blood_request.accepted_date = timezone.now()
#                 blood_request.save()
#
#                 print("Request status updated to approved")
#                 print("Accepted Date:", blood_request.accepted_date)
#
#                 # 🔥 ADD REWARD & NEXT DATE
#                 try:
#                     profile = UserProfile.objects.get(
#                         USER=blood_request.receiver
#                     )
#
#                     print("UserProfile Found")
#                     print("Old Reward Points:", profile.reward_points)
#
#                     # Ensure integer (if still CharField in DB)
#                     profile.reward_points = int(profile.reward_points) + 100
#
#                     profile.next_request_allowed_date = (
#                         timezone.now().date() + timedelta(days=70)
#                     )
#
#                     print("New Reward Points:", profile.reward_points)
#                     print("Next Request Allowed Date:",
#                           profile.next_request_allowed_date)
#
#                     profile.save()
#                     print("Profile updated successfully")
#
#                 except UserProfile.DoesNotExist:
#                     print("UserProfile NOT found")
#
#             # ================= REJECT =================
#             elif action == "reject":
#
#                 print("Rejecting request...")
#
#                 blood_request.status = "rejected"
#                 blood_request.save()
#
#                 print("Request status updated to rejected")
#
#             else:
#                 print("Invalid action received")
#                 return JsonResponse({
#                     "status": "error",
#                     "message": "Invalid action"
#                 })
#
#         print("Transaction completed successfully")
#         print("========== END ==========\n")
#
#         return JsonResponse({
#             "status": "ok",
#             "message": f"Request {action}d successfully"
#         })
#
#     except BloodRequest.DoesNotExist:
#         print("BloodRequest NOT found")
#         return JsonResponse({
#             "status": "error",
#             "message": "Request not found"
#         })
#
#     except Exception as e:
#         print("ERROR:", str(e))
#         return JsonResponse({
#             "status": "error",
#             "message": str(e)
#         })


#
# @csrf_exempt
# def create_broadcast_request(request):
#
#     if request.method != "POST":
#         return JsonResponse({"status": "error", "message": "Invalid method"})
#
#     try:
#         data = json.loads(request.body)
#
#         sender_id = data.get("sender_id")
#         blood_group = data.get("blood_group")
#         units = int(data.get("units"))
#         required_date = data.get("required_date")
#         required_time = data.get("required_time")
#
#         sender = User.objects.get(id=int(sender_id))
#         profile = UserProfile.objects.get(USER=sender)
#
#         today = timezone.now().date()
#
#         # ✅ CHECK next request allowed date
#         if profile.next_request_allowed_date:
#             if profile.next_request_allowed_date > today:
#                 return JsonResponse({
#                     "status": "error",
#                     "message": f"You can request again after {profile.next_request_allowed_date}"
#                 })
#
#         parsed_date = datetime.strptime(required_date, "%Y-%m-%d").date()
#         parsed_time = datetime.strptime(required_time, "%I:%M %p").time()
#
#         BloodBroadcastRequest.objects.create(
#             sender=sender,
#             blood_group=blood_group,
#             total_units=units,
#             remaining_units=units,
#             required_date=parsed_date,
#             required_time=parsed_time,
#             status="open"
#         )
#
#         return JsonResponse({
#             "status": "ok",
#             "message": "Broadcast request created"
#         })
#
#     except Exception as e:
#         return JsonResponse({"status": "error", "message": str(e)})


@csrf_exempt
def create_broadcast_request(request):

    if request.method != "POST":
        return JsonResponse({"status": "error", "message": "Invalid method"})

    try:
        data = json.loads(request.body)

        sender_id = data.get("sender_id")
        blood_group = data.get("blood_group")
        units = int(data.get("units"))
        required_date = data.get("required_date")
        required_time = data.get("required_time")

        sender = User.objects.get(id=int(sender_id))

        parsed_date = datetime.strptime(required_date, "%Y-%m-%d").date()
        parsed_time = datetime.strptime(required_time, "%I:%M %p").time()

        BloodBroadcastRequest.objects.create(
            sender=sender,
            blood_group=blood_group,
            total_units=units,
            remaining_units=units,
            required_date=parsed_date,
            required_time=parsed_time,
            status="open"
        )

        return JsonResponse({
            "status": "ok",
            "message": "Broadcast request created successfully"
        })

    except Exception as e:
        return JsonResponse({
            "status": "error",
            "message": str(e)
        })



@csrf_exempt
def view_broadcast_requests(request):

    if request.method != "POST":
        return JsonResponse({"status": "error"})

    try:
        data = json.loads(request.body)
        user_id = data.get("user_id")

        user = User.objects.get(id=int(user_id))
        profile = UserProfile.objects.get(USER=user)

        today = timezone.now().date()

        # ✅ BLOCK if not eligible yet
        if profile.next_request_allowed_date:
            if profile.next_request_allowed_date > today:
                return JsonResponse({
                    "status": "error",
                    "message": f"You can donate again after {profile.next_request_allowed_date}"
                })

        # ✅ Blood group match + open request
        requests = BloodBroadcastRequest.objects.filter(
            blood_group=profile.blood_group,
            status="open",
            remaining_units__gt=0
        ).exclude(sender=user)

        response_data = []

        for req in requests:

            # skip if already responded
            if BloodBroadcastResponse.objects.filter(
                    request=req,
                    donor=user).exists():
                continue

            response_data.append({
                "request_id": req.id,
                "sender_name": req.sender.username,
                "blood_group": req.blood_group,
                "remaining_units": req.remaining_units,
                "required_date": str(req.required_date),
                "required_time": req.required_time.strftime("%I:%M %p"),
            })

        return JsonResponse({
            "status": "ok",
            "requests": response_data
        })

    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)})


@csrf_exempt
@transaction.atomic
def respond_broadcast_request(request):

    if request.method != "POST":
        return JsonResponse({"status": "error"})

    try:
        data = json.loads(request.body)

        request_id = data.get("request_id")
        donor_id = data.get("donor_id")
        action = data.get("action")  # accepted / rejected

        donor = User.objects.select_for_update().get(id=int(donor_id))
        donor_profile = UserProfile.objects.select_for_update().get(USER=donor)

        broadcast_request = BloodBroadcastRequest.objects.select_for_update().get(
            id=int(request_id)
        )

        today = timezone.now().date()

        # ✅ Check donor eligibility
        if donor_profile.next_request_allowed_date:
            if donor_profile.next_request_allowed_date > today:
                return JsonResponse({
                    "status": "error",
                    "message": f"You can donate again after {donor_profile.next_request_allowed_date}"
                })

        # ✅ Blood group validation
        if donor_profile.blood_group != broadcast_request.blood_group:
            return JsonResponse({
                "status": "error",
                "message": "Blood group does not match"
            })

        if broadcast_request.remaining_units <= 0:
            return JsonResponse({
                "status": "error",
                "message": "Request already completed"
            })

        # prevent duplicate
        if BloodBroadcastResponse.objects.filter(
                request=broadcast_request,
                donor=donor).exists():
            return JsonResponse({
                "status": "error",
                "message": "Already responded"
            })

        BloodBroadcastResponse.objects.create(
            request=broadcast_request,
            donor=donor,
            response=action
        )

        # ✅ If ACCEPTED
        if action == "accepted":

            # reduce unit
            broadcast_request.remaining_units -= 1

            if broadcast_request.remaining_units <= 0:
                broadcast_request.status = "completed"

            broadcast_request.save()

            # 🔥 Add 100 reward points
            current_points = int(donor_profile.reward_points)
            donor_profile.reward_points = str(current_points + 100)

            # 🔥 Set 75 days restriction
            donor_profile.next_request_allowed_date = today + timedelta(days=75)

            donor_profile.save()

        return JsonResponse({
            "status": "ok",
            "message": f"Request {action} successfully"
        })

    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)})


import google.generativeai as genai
from django.conf import settings
from django.views.decorators.csrf import csrf_exempt
from django.http import JsonResponse
from django.contrib.auth.models import User
from django.utils import timezone
from .models import HealthVitals, UserProfile
import json


genai.configure(api_key=settings.GEMINI_API_KEY)


@csrf_exempt
def upload_vitals(request):

    if request.method != "POST":
        return JsonResponse({"status": "error", "message": "Invalid request"})

    try:
        lid = request.POST.get("lid")
        hemoglobin = request.POST.get("hemoglobin")
        blood_pressure = request.POST.get("blood_pressure")
        sugar_level = request.POST.get("sugar_level")
        weight = request.POST.get("weight")

        image = request.FILES.get("image")

        user = User.objects.get(id=lid)

        # ---------------- SAVE VITALS ----------------
        vitals = HealthVitals.objects.create(
            USER=user,
            hemoglobin=hemoglobin,
            blood_pressure=blood_pressure,
            sugar_level=sugar_level,
            weight=weight,
            image=image
        )

        # ---------------- GEMINI ANALYSIS ----------------
        model = genai.GenerativeModel("gemini-2.5-flash")

        prompt = f"""
        Analyze the following medical vitals and give a health score between 0 to 100.
        Respond only with a number.

        Hemoglobin: {hemoglobin}
        Blood Pressure: {blood_pressure}
        Sugar Level: {sugar_level}
        Weight: {weight}
        """

        response = model.generate_content(prompt)

        gemini_result = response.text.strip()

        print("Gemini Raw Response:", gemini_result)

        try:
            score = int(''.join(filter(str.isdigit, gemini_result)))
            if score > 100:
                score = 100
        except:
            score = 50  # fallback

        # ---------------- UPDATE PROFILE ----------------
        profile = UserProfile.objects.get(USER=user)
        profile.health_score = str(score)
        profile.save()

        return JsonResponse({
            "status": "ok",
            "message": "Vitals uploaded successfully",
            "health_score": score
        })

    except Exception as e:
        print("ERROR:", str(e))
        return JsonResponse({
            "status": "error",
            "message": str(e)
        })




@csrf_exempt
def view_latest_vitals(request):

    if request.method != "POST":
        return JsonResponse({
            "status": "error",
            "message": "Invalid request"
        })

    try:
        data = json.loads(request.body)
        user_id = data.get("user_id")

        if not user_id:
            return JsonResponse({
                "status": "error",
                "message": "User ID required"
            })

        user = User.objects.get(id=int(user_id))

        latest_vitals = HealthVitals.objects.filter(
            USER=user
        ).order_by("-date").first()

        if not latest_vitals:
            return JsonResponse({
                "status": "error",
                "message": "No vitals found"
            })

        image_url = ""
        if latest_vitals.image:
            image_url = request.build_absolute_uri(
                latest_vitals.image.url
            )

        return JsonResponse({
            "status": "ok",
            "hemoglobin": latest_vitals.hemoglobin,
            "blood_pressure": latest_vitals.blood_pressure,
            "sugar_level": latest_vitals.sugar_level,
            "weight": latest_vitals.weight,
            "date": str(latest_vitals.date),
            "image": image_url
        })

    except Exception as e:
        print("ERROR:", str(e))
        return JsonResponse({
            "status": "error",
            "message": str(e)
        })


@csrf_exempt
def add_meal_time(request):
    if request.method == "POST":

        lid = request.POST.get("lid")
        breakfast = request.POST.get("breakfast_time")
        lunch = request.POST.get("lunch_time")
        dinner = request.POST.get("dinner_time")

        try:
            user = User.objects.get(id=lid)

            breakfast_time = datetime.strptime(breakfast, "%H:%M").time()
            lunch_time = datetime.strptime(lunch, "%H:%M").time()
            dinner_time = datetime.strptime(dinner, "%H:%M").time()

            UserMealTime.objects.update_or_create(
                USER=user,
                defaults={
                    "breakfast_time": breakfast_time,
                    "lunch_time": lunch_time,
                    "dinner_time": dinner_time,
                }
            )

            return JsonResponse({"status": "ok"})

        except Exception as e:
            return JsonResponse({"status": "error", "message": str(e)})

    return JsonResponse({"status": "error"})


@csrf_exempt
def view_meal_time(request):
    if request.method == "POST":

        lid = request.POST.get("lid")

        try:
            user = User.objects.get(id=lid)
            meal = UserMealTime.objects.get(USER=user)

            return JsonResponse({
                "status": "ok",
                "breakfast_time": meal.breakfast_time.strftime("%H:%M"),
                "lunch_time": meal.lunch_time.strftime("%H:%M"),
                "dinner_time": meal.dinner_time.strftime("%H:%M"),
            })

        except UserMealTime.DoesNotExist:
            return JsonResponse({"status": "not_found"})

        except Exception as e:
            return JsonResponse({"status": "error", "message": str(e)})

    return JsonResponse({"status": "error"})

#MEDICINE REMINDER
# import json
# import base64
# import re
# from datetime import datetime, timedelta, date
# import google.generativeai as genai
# from django.conf import settings
# from django.http import JsonResponse
# from django.views.decorators.csrf import csrf_exempt
# from django.contrib.auth.models import User
# from .models import Prescription, MedicineSchedule, UserMealTime
#
#
# genai.configure(api_key=settings.GEMINI_API_KEY)
#
#
# @csrf_exempt
# def upload_prescription(request):
#
#     if request.method == "POST":
#
#         lid = request.POST.get("lid")
#         image = request.FILES.get("image")
#
#         if not lid or not image:
#             return JsonResponse({"status": "error", "message": "Missing data"})
#
#         try:
#             user = User.objects.get(id=lid)
#
#             prescription = Prescription.objects.create(
#                 USER=user,
#                 image=image
#             )
#
#             with open(prescription.image.path, "rb") as f:
#                 image_bytes = f.read()
#
#             encoded_image = base64.b64encode(image_bytes).decode("utf-8")
#
#             model = genai.GenerativeModel("gemini-2.5-flash")
#
#             prompt = """
#             Extract medicines from prescription.
#             Return JSON:
#
#             [
#               {
#                 "medicine_name": "...",
#                 "time_of_day": "morning"
#               }
#             ]
#
#             Use only morning, afternoon, night.
#             Convert evening to night.
#             """
#
#             response = model.generate_content(
#                 [
#                     {
#                         "role": "user",
#                         "parts": [
#                             {"text": prompt},
#                             {
#                                 "inline_data": {
#                                     "mime_type": "image/jpeg",
#                                     "data": encoded_image
#                                 }
#                             }
#                         ]
#                     }
#                 ]
#             )
#
#             raw_output = response.text.strip()
#             json_match = re.search(r'\[.*\]', raw_output, re.DOTALL)
#
#             if not json_match:
#                 return JsonResponse({"status": "error", "message": "AI parse error"})
#
#             medicines = json.loads(json_match.group())
#
#             meal_time = UserMealTime.objects.get(USER=user)
#             today = date.today()
#
#             saved_medicines = []
#
#             for med in medicines:
#
#                 time_of_day = med.get("time_of_day")
#
#                 if time_of_day == "morning":
#                     base_time = meal_time.breakfast_time
#                 elif time_of_day == "afternoon":
#                     base_time = meal_time.lunch_time
#                 else:
#                     base_time = meal_time.dinner_time
#
#                 # PURE LOCAL DATETIME (NO TIMEZONE)
#                 base_datetime = datetime.combine(today, base_time)
#                 reminder_time = base_datetime - timedelta(minutes=5)
#
#                 medicine_obj = MedicineSchedule.objects.create(
#                     USER=user,
#                     prescription=prescription,
#                     medicine_name=med.get("medicine_name"),
#                     time_of_day=time_of_day,
#                     food_relation="before",
#                     minutes_offset=5,
#                     next_reminder=reminder_time
#                 )
#
#                 saved_medicines.append({
#                     "medicine_name": medicine_obj.medicine_name,
#                     "time_of_day": time_of_day,
#                     "reminder_time": reminder_time.strftime("%Y-%m-%d %H:%M:%S")
#                 })
#
#             return JsonResponse({
#                 "status": "ok",
#                 "medicines": saved_medicines
#             })
#
#         except Exception as e:
#             return JsonResponse({"status": "error", "message": str(e)})
#
#     return JsonResponse({"status": "error"})


# MEDICINE REMINDER WITH DURATION SUPPORT

import json
import base64
import re
from datetime import datetime, timedelta, date
import google.generativeai as genai
from django.conf import settings
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth.models import User
from .models import Prescription, MedicineSchedule, UserMealTime


genai.configure(api_key=settings.GEMINI_API_KEY)


@csrf_exempt
def upload_prescription(request):

    if request.method == "POST":

        lid = request.POST.get("lid")
        image = request.FILES.get("image")

        if not lid or not image:
            return JsonResponse({"status": "error", "message": "Missing data"})

        try:
            user = User.objects.get(id=lid)

            prescription = Prescription.objects.create(
                USER=user,
                image=image
            )

            with open(prescription.image.path, "rb") as f:
                image_bytes = f.read()

            encoded_image = base64.b64encode(image_bytes).decode("utf-8")

            model = genai.GenerativeModel("gemini-2.5-flash")

            prompt = """
            Extract medicines from prescription.

            Return JSON:

            [
              {
                "medicine_name": "...",
                "time_of_day": "morning",
                "duration_days": 3
              }
            ]

            Rules:
            - Use only morning, afternoon, night
            - Convert evening to night
            - If days mentioned (like 3 days / 5 days / for 1 week),
              extract integer days.
            - If not mentioned assume 1 day.
            - Return JSON only.
            """

            response = model.generate_content(
                [
                    {
                        "role": "user",
                        "parts": [
                            {"text": prompt},
                            {
                                "inline_data": {
                                    "mime_type": "image/jpeg",
                                    "data": encoded_image
                                }
                            }
                        ]
                    }
                ]
            )

            raw_output = response.text.strip()
            json_match = re.search(r'\[.*\]', raw_output, re.DOTALL)

            if not json_match:
                return JsonResponse({"status": "error", "message": "AI parse error"})

            medicines = json.loads(json_match.group())

            meal_time = UserMealTime.objects.get(USER=user)
            today = date.today()

            saved_medicines = []

            for med in medicines:

                time_of_day = med.get("time_of_day")
                duration = int(med.get("duration_days", 1))

                if time_of_day == "morning":
                    base_time = meal_time.breakfast_time
                elif time_of_day == "afternoon":
                    base_time = meal_time.lunch_time
                else:
                    base_time = meal_time.dinner_time

                for day in range(duration):

                    target_date = today + timedelta(days=day)

                    base_datetime = datetime.combine(target_date, base_time)
                    reminder_time = base_datetime - timedelta(minutes=5)

                    medicine_obj = MedicineSchedule.objects.create(
                        USER=user,
                        prescription=prescription,
                        medicine_name=med.get("medicine_name"),
                        time_of_day=time_of_day,
                        food_relation="before",
                        minutes_offset=5,
                        next_reminder=reminder_time
                    )

                    saved_medicines.append({
                        "medicine_name": medicine_obj.medicine_name,
                        "time_of_day": time_of_day,
                        "reminder_time": reminder_time.strftime("%Y-%m-%d %H:%M:%S")
                    })

            return JsonResponse({
                "status": "ok",
                "medicines": saved_medicines
            })

        except Exception as e:
            return JsonResponse({"status": "error", "message": str(e)})

    return JsonResponse({"status": "error"})


from django.utils import timezone
from django.db.models import Q
from datetime import datetime, timedelta


def get_upcoming_medicines(request):
    if request.method == 'POST':
        lid = request.POST.get('lid')

        try:
            user = User.objects.get(id=lid)
            current_time = timezone.now()

            medicines = MedicineSchedule.objects.filter(
                USER=user
            ).exclude(
                next_reminder__isnull=True
            ).order_by('next_reminder')

            medicine_list = []
            for med in medicines:
                if med.next_reminder and med.next_reminder >= current_time:
                    medicine_list.append({
                        'id': med.id,
                        'medicine_name': med.medicine_name,
                        'time_of_day': med.time_of_day,
                        'food_relation': med.food_relation,
                        'next_reminder': med.next_reminder.isoformat(),
                    })

            return JsonResponse({
                'status': 'ok',
                'medicines': medicine_list
            })

        except User.DoesNotExist:
            return JsonResponse({'status': 'error', 'message': 'User not found'})

    return JsonResponse({'status': 'error', 'message': 'Invalid request'})


from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth.models import User
from django.db.models import Q
from .models import BloodBroadcastRequest, BloodBroadcastResponse, UserProfile
import json


@csrf_exempt
def view_accepted_requests(request):

    print("\n========== VIEW ACCEPTED REQUESTS API CALLED ==========")

    if request.method != "POST":
        return JsonResponse({"status": "error", "message": "POST only"})

    try:
        data = json.loads(request.body)
        user_id = data.get("user_id")

        print("User ID:", user_id)

        if not user_id:
            return JsonResponse({
                "status": "error",
                "message": "user_id is required"
            })

        sender = User.objects.get(id=int(user_id))

        my_requests = BloodBroadcastRequest.objects.filter(sender=sender)

        accepted_responses = BloodBroadcastResponse.objects.filter(
            request__in=my_requests,
            response="accepted"
        ).select_related("donor", "request")

        result = []

        for res in accepted_responses:

            donor_profile = UserProfile.objects.get(USER=res.donor)
            if donor_profile.profile_picture:
                profile_picture_url = request.build_absolute_uri(
                    donor_profile.profile_picture.url
                )
            else:
                profile_picture_url = ""

            print("Donor ID:", res.donor.id)
            print("Donor Name:", donor_profile.name)

            result.append({
                "request_id": res.request.id,
                "blood_group": res.request.blood_group,
                "total_units": res.request.total_units,
                "remaining_units": res.request.remaining_units,
                "required_date": res.request.required_date.strftime("%Y-%m-%d"),
                "required_time": res.request.required_time.strftime("%I:%M %p"),
                "donor_id": res.donor.id,
                "donor_name": donor_profile.name,
                "donor_email": donor_profile.email,
                "donor_phone": donor_profile.phone,
                "donor_address": donor_profile.address,
                "donor_profile_picture": profile_picture_url
            })

        print("Final Response:", result)

        return JsonResponse({
            "status": "ok",
            "data": result
        })

    except Exception as e:
        print("❌ Exception:", str(e))
        return JsonResponse({
            "status": "error",
            "message": str(e)
        })



@csrf_exempt
def users_send_chat(request):

    print("\n========== USERS SEND CHAT API CALLED ==========")

    if request.method != "POST":
        print("❌ Not POST request")
        return JsonResponse({"status": "error", "message": "POST only"})

    try:
        print("Raw Body:", request.body)

        data = json.loads(request.body)
        print("Decoded Data:", data)

        sender_id = data.get("sender_id")
        receiver_id = data.get("receiver_id")
        message = data.get("message")

        print("Sender ID:", sender_id)
        print("Receiver ID:", receiver_id)
        print("Message:", message)

        if not sender_id or not receiver_id or not message:
            print("❌ Missing fields")
            return JsonResponse({
                "status": "error",
                "message": "Missing required fields"
            })

        sender = User.objects.get(id=sender_id)
        receiver = User.objects.get(id=receiver_id)

        print("Sender Object:", sender)
        print("Receiver Object:", receiver)

        chat = Chat.objects.create(
            SENDER=sender,
            RECEIVER=receiver,
            message=message,
            date_time=timezone.now().strftime("%Y-%m-%d %H:%M:%S")
        )

        print("✅ Chat Created ID:", chat.id)

        return JsonResponse({
            "status": "ok",
            "chat_id": chat.id
        })

    except Exception as e:
        print("❌ Exception:", str(e))
        return JsonResponse({
            "status": "error",
            "message": str(e)
        })


@csrf_exempt
def users_view_chat(request):

    print("\n========== USERS VIEW CHAT API CALLED ==========")

    if request.method != "POST":
        print("❌ Not POST request")
        return JsonResponse({"status": "error", "message": "POST only"})

    try:
        print("Raw Body:", request.body)

        data = json.loads(request.body)
        print("Decoded Data:", data)

        sender_id = data.get("sender_id")
        receiver_id = data.get("receiver_id")

        print("Sender ID:", sender_id)
        print("Receiver ID:", receiver_id)

        if not sender_id or not receiver_id:
            print("❌ Missing IDs")
            return JsonResponse({
                "status": "error",
                "message": "IDs required"
            })

        chats = Chat.objects.filter(
            Q(SENDER_id=sender_id, RECEIVER_id=receiver_id) |
            Q(SENDER_id=receiver_id, RECEIVER_id=sender_id)
        ).order_by("date_time")

        print("Total Chats Found:", chats.count())

        result = []

        for chat in chats:
            print("Chat ID:", chat.id,
                  "| Sender:", chat.SENDER.id,
                  "| Receiver:", chat.RECEIVER.id,
                  "| Message:", chat.message)

            result.append({
                "chat_id": chat.id,
                "message": chat.message,
                "sender_id": chat.SENDER.id,
                "receiver_id": chat.RECEIVER.id,
                "date_time": chat.date_time
            })

        return JsonResponse({
            "status": "ok",
            "total_messages": len(result),
            "data": result
        })

    except Exception as e:
        print("❌ Exception:", str(e))
        return JsonResponse({
            "status": "error",
            "message": str(e)
        })


@csrf_exempt
def view_my_accepted_broadcasts(request):

    print("\n========== VIEW MY ACCEPTED BROADCASTS ==========")

    if request.method != "POST":
        return JsonResponse({
            "status": "error",
            "message": "POST only"
        })

    try:
        data = json.loads(request.body)
        user_id = data.get("user_id")

        if not user_id:
            return JsonResponse({
                "status": "error",
                "message": "user_id required"
            })

        donor = User.objects.get(id=int(user_id))

        print("Donor ID:", donor.id)

        accepted_responses = BloodBroadcastResponse.objects.filter(
            donor=donor,
            response="accepted"
        ).select_related("request__sender")

        result = []

        for res in accepted_responses:

            request_obj = res.request
            sender = request_obj.sender

            try:
                sender_profile = UserProfile.objects.get(USER=sender)
                sender_name = sender_profile.name
                sender_phone = sender_profile.phone
                sender_email = sender_profile.email
            except UserProfile.DoesNotExist:
                sender_name = sender.username
                sender_phone = ""
                sender_email = ""

            result.append({
                "request_id": request_obj.id,

                # 🔥 IMPORTANT FOR CHAT
                "sender_id": sender.id,

                "sender_name": sender_name,
                "sender_phone": sender_phone,
                "sender_email": sender_email,

                "blood_group": request_obj.blood_group,
                "total_units": request_obj.total_units,
                "remaining_units": request_obj.remaining_units,

                "required_date":
                    request_obj.required_date.strftime("%Y-%m-%d")
                    if request_obj.required_date else "",

                "responded_at":
                    res.responded_at.strftime("%d-%m-%Y %H:%M")
            })

        return JsonResponse({
            "status": "ok",
            "data": result
        })

    except Exception as e:
        print("❌ Exception:", str(e))
        return JsonResponse({
            "status": "error",
            "message": str(e)
        })

from django.http import JsonResponse
from django.db.models.functions import Cast
from django.db.models import IntegerField
from .models import UserProfile


def leaderboard_users(request):
    try:
        user_id = request.GET.get("user_id")

        # Convert reward_points string to integer for proper sorting
        users = UserProfile.objects.annotate(
            reward_int=Cast("reward_points", IntegerField())
        ).order_by("-reward_int")

        leaderboard = []
        current_user = None
        rank = 1

        for u in users:

            entry = {
                "rank": rank,
                "user_id": u.USER.id,
                "name": u.name,
                "blood_group": u.blood_group,
                "reward_points": u.reward_points,
                "profile_picture": request.build_absolute_uri(u.profile_picture.url) if u.profile_picture else ""
            }

            if str(u.USER.id) == str(user_id):
                current_user = entry

            if rank <= 10:
                leaderboard.append(entry)

            rank += 1

        return JsonResponse({
            "status": "ok",
            "leaderboard": leaderboard,
            "current_user": current_user
        })

    except Exception as e:
        return JsonResponse({
            "status": "error",
            "message": str(e)
        })



def view_my_broadcast_requests(request):

    try:

        user_id = request.GET.get("user_id")

        requests = BloodBroadcastRequest.objects.filter(
            sender_id=user_id
        ).order_by("-created_at")

        data = []

        for r in requests:

            data.append({
                "id": r.id,
                "blood_group": r.blood_group,
                "total_units": r.total_units,
                "remaining_units": r.remaining_units,
                "required_date": str(r.required_date),
                "required_time": str(r.required_time),
                "status": r.status,
                "created_at": str(r.created_at)
            })

        return JsonResponse({
            "status": "ok",
            "data": data
        })

    except Exception as e:

        return JsonResponse({
            "status": "error",
            "message": str(e)
        })