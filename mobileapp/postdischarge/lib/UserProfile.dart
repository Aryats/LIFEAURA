// #USER PROFILE
// @csrf_exempt
// def user_login(request):
// if request.method == "POST":
// try:
// if not request.body:
// return JsonResponse({"status": "error", "message": "Empty request body"}, status=400)
//
// data = json.loads(request.body)
// username = data.get("username")
// password = data.get("password")
//
// if not username or not password:
// return JsonResponse({"status": "error", "message": "Username and password are required"}, status=400)
//
// user = authenticate(request, username=username, password=password)
// if user is None:
// return JsonResponse({"status": "error", "message": "Invalid username or password"}, status=401)
//
// if user.is_superuser:
// return JsonResponse({"status": "error", "message": "Superusers are not allowed to login"}, status=403)
//
// django_login(request, user)
//
// # Get AppUser data to return
// try:
// app_user = AppUser.objects.get(USER=user)
// return JsonResponse({
// "status": "success",
// "message": "Login successful",
// "user_id": user.id,
// "username": user.username,
// "name": app_user.name,
// "email": app_user.email
// }, status=200)
// except AppUser.DoesNotExist:
// return JsonResponse({"status": "error", "message": "User profile not found"}, status=404)
//
// except json.JSONDecodeError:
// return JsonResponse({"status": "error", "message": "Invalid JSON format"}, status=400)
// except Exception as e:
// return JsonResponse({"status": "error", "message": f"Server error: {str(e)}"}, status=500)
//
// return JsonResponse({"status": "error", "message": "Only POST allowed"}, status=405)
//
//
// @login_required
// @csrf_exempt
// def user_profile(request):
// if request.method == "GET":
// try:
// app_user = AppUser.objects.get(USER=request.user)
// profile_data = {
// "name": app_user.name,
// "email": app_user.email,
// "phone": app_user.phone,
// "skills": app_user.skills,
// "preferences": app_user.preferences,
// "cv": request.build_absolute_uri(app_user.cv.url) if app_user.cv else None,
// }
// return JsonResponse({"status": "success", "data": profile_data}, status=200)
//
// except AppUser.DoesNotExist:
// return JsonResponse({"status": "error", "message": "User profile not found"}, status=404)
// except Exception as e:
// return JsonResponse({"status": "error", "message": str(e)}, status=500)
//
// return JsonResponse({"status": "error", "message": "Only GET allowed"}, status=405)
//
//
// #EDIT_PROFILE
// #EDIT_PROFILE
// @login_required
// @csrf_exempt
// def edit_profile(request):
// if request.method == "POST":
// try:
// app_user = AppUser.objects.get(USER=request.user)
//
// # Handle form data
// if request.content_type == 'application/json':
// # JSON data
// data = json.loads(request.body)
// app_user.name = data.get('name', app_user.name)
// app_user.email = data.get('email', app_user.email)
// app_user.phone = data.get('phone', app_user.phone)
// app_user.skills = data.get('skills', app_user.skills)
// app_user.preferences = data.get('preferences', app_user.preferences)
//
// else:
// # Form data (for file upload)
// app_user.name = request.POST.get('name', app_user.name)
// app_user.email = request.POST.get('email', app_user.email)
// app_user.phone = request.POST.get('phone', app_user.phone)
// app_user.skills = request.POST.get('skills', app_user.skills)
//
// # Handle CV file upload
// if 'cv' in request.FILES:
// cv_file = request.FILES['cv']
//
// # Delete old CV if exists
// if app_user.cv:
// default_storage.delete(app_user.cv.path)
//
// # Save new CV
// app_user.cv.save(cv_file.name, cv_file)
//
// # 🔹 Extract skills from the uploaded CV
// extracted_skills = extract_skills_from_pdf(cv_file)
// app_user.preferences = extracted_skills
//
// else:
// # Keep existing preferences if no CV uploaded
// app_user.preferences = request.POST.get('preferences', app_user.preferences)
//
// app_user.save()
//
// return JsonResponse({
// "status": "success",
// "message": "Profile updated successfully",
// "data": {
// "name": app_user.name,
// "email": app_user.email,
// "phone": app_user.phone,
// "skills": app_user.skills,
// "preferences": app_user.preferences,
// "cv": request.build_absolute_uri(app_user.cv.url) if app_user.cv else None,
// }
// }, status=200)
//
// except AppUser.DoesNotExist:
// return JsonResponse({"status": "error", "message": "User profile not found"}, status=404)
// except Exception as e:
// return JsonResponse({"status": "error", "message": f"Server error: {str(e)}"}, status=500)
//
// elif request.method == "GET":
// # Return current profile data for editing
// try:
// app_user = AppUser.objects.get(USER=request.user)
// profile_data = {
// "name": app_user.name,
// "email": app_user.email,
// "phone": app_user.phone,
// "skills": app_user.skills,
// "preferences": app_user.preferences,
// "cv": request.build_absolute_uri(app_user.cv.url) if app_user.cv else None,
// }
// return JsonResponse({"status": "success", "data": profile_data}, status=200)
//
// except AppUser.DoesNotExist:
// return JsonResponse({"status": "error", "message": "User profile not found"}, status=404)
// except Exception as e:
// return JsonResponse({"status": "error", "message": str(e)}, status=500)
//
// return JsonResponse({"status": "error", "message": "Only POST and GET allowed"}, status=405)