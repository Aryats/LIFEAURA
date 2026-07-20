from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone


class UserProfile(models.Model):
    USER = models.OneToOneField(User, on_delete=models.CASCADE)
    name = models.CharField(max_length=200)
    email = models.CharField(max_length=200)
    phone = models.CharField(max_length=200)
    blood_group = models.CharField(max_length=200)
    address = models.CharField(max_length=200)
    reward_points = models.CharField(max_length=200,default="0")
    health_score = models.CharField(max_length=200,default="0")
    profile_picture = models.ImageField(upload_to='profiles/', null=True, blank=True)
    next_request_allowed_date = models.DateField(null=True, blank=True)
    last_penalty_date = models.DateField(null=True, blank=True)


class Hospital(models.Model):
    STATUS_CHOICES = (('pending', 'Pending'),('approved', 'Approved'),('rejected', 'Rejected'),)
    USER = models.OneToOneField(User, on_delete=models.CASCADE)
    hospital_name = models.CharField(max_length=200)
    email = models.CharField(max_length=200)
    phone = models.CharField(max_length=200)
    address = models.CharField(max_length=200)
    status = models.CharField(max_length=200, choices=STATUS_CHOICES, default='pending')

class Category(models.Model):
    category_name = models.CharField(max_length=100)

class Organization(models.Model):
    STATUS_CHOICES = (('pending', 'Pending'),('approved', 'Approved'),('rejected', 'Rejected'),)
    USER = models.OneToOneField(User, on_delete=models.CASCADE)
    category = models.ForeignKey(Category, on_delete=models.CASCADE)
    organisation_name = models.CharField(max_length=200)
    email = models.CharField(max_length=200)
    phone = models.CharField(max_length=15)
    address =models.CharField(max_length=200)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='pending')



class BloodRequest(models.Model):

    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
    ]

    BLOOD_CHOICES = [
        ('A+', 'A+'), ('A-', 'A-'),
        ('B+', 'B+'), ('B-', 'B-'),
        ('O+', 'O+'), ('O-', 'O-'),
        ('AB+', 'AB+'), ('AB-', 'AB-'),
    ]

    sender = models.ForeignKey(User,on_delete=models.CASCADE,related_name='sent_requests' )

    receiver = models.ForeignKey(User,on_delete=models.CASCADE,related_name='received_requests')

    blood_group = models.CharField(max_length=3,choices=BLOOD_CHOICES)

    units = models.PositiveIntegerField(null=True,blank=True)

    time = models.TimeField(null=True,blank=True)

    required_date = models.DateField(null=True,blank=True)

    status = models.CharField(max_length=10,choices=STATUS_CHOICES,default='pending')

    request_date = models.DateTimeField(auto_now_add=True)

    accepted_date = models.DateTimeField(null=True,blank=True)



class DonationHistory(models.Model):
    USER = models.ForeignKey(User, on_delete=models.CASCADE)
    REQUEST = models.ForeignKey(BloodRequest, on_delete=models.CASCADE)
    donation_date = models.CharField(max_length=200)
    points_earned = models.CharField(max_length=200)

class RewardTransaction(models.Model):
    CHANGE_CHOICES = (
        ('add', 'Add'),
        ('deduct', 'Deduct'),
    )

    USER = models.ForeignKey(User, on_delete=models.CASCADE)
    change_type = models.CharField(max_length=10, choices=CHANGE_CHOICES)
    points = models.CharField(max_length=200)
    reason = models.CharField(max_length=255)
    date = models.CharField(max_length=200)


class HealthVitals(models.Model):
    USER = models.ForeignKey(User, on_delete=models.CASCADE)
    hemoglobin = models.CharField(max_length=200)
    blood_pressure = models.CharField(max_length=20)
    sugar_level = models.CharField(max_length=200)
    weight = models.CharField(max_length=200)
    image = models.ImageField(upload_to="vitals/", null=True, blank=True)
    date = models.DateField(auto_now_add=True)

class Chat(models.Model):
    SENDER = models.ForeignKey(User,on_delete=models.CASCADE,related_name='fromperson')
    RECEIVER = models.ForeignKey(User,on_delete=models.CASCADE,related_name='toperson')
    message = models.CharField(max_length=255)
    date_time = models.CharField(max_length=255)

class CalendarEvent(models.Model):
    ORGANIZATION = models.ForeignKey(User, on_delete=models.CASCADE)
    title = models.CharField(max_length=200)
    description = models.CharField(max_length=200)
    event_date = models.CharField(max_length=200)

class Prescription(models.Model):
    USER = models.ForeignKey(User, on_delete=models.CASCADE)
    image = models.ImageField(upload_to="prescriptions/")
    uploaded_at = models.DateTimeField(default=timezone.now)


class UserMealTime(models.Model):
    USER = models.OneToOneField(User, on_delete=models.CASCADE)
    breakfast_time = models.TimeField()
    lunch_time = models.TimeField()
    dinner_time = models.TimeField()
    updated_at = models.DateTimeField(auto_now=True)


class MedicineSchedule(models.Model):

    TIME_CHOICES = [
        ("morning", "Morning"),
        ("afternoon", "Afternoon"),
        ("night", "Night"),
    ]

    FOOD_CHOICES = [
        ("before", "Before Food"),
        ("after", "After Food"),
    ]

    USER = models.ForeignKey(User, on_delete=models.CASCADE)
    prescription = models.ForeignKey(
        Prescription,
        on_delete=models.CASCADE,
        null=True,
        blank=True
    )

    medicine_name = models.CharField(max_length=200)
    time_of_day = models.CharField(max_length=20, choices=TIME_CHOICES)
    food_relation = models.CharField(max_length=20, choices=FOOD_CHOICES)
    minutes_offset = models.IntegerField(default=0)
    next_reminder = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)



class ChatMessage(models.Model):
    USER = models.ForeignKey(User, on_delete=models.CASCADE)
    role = models.CharField(max_length=10, choices=[
        ('user', 'User'),
        ('bot', 'Bot')
    ])
    message = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)




class BloodBroadcastRequest(models.Model):

    STATUS_CHOICES = [
        ('open', 'Open'),
        ('completed', 'Completed'),
    ]

    BLOOD_CHOICES = [
        ('A+', 'A+'), ('A-', 'A-'),
        ('B+', 'B+'), ('B-', 'B-'),
        ('O+', 'O+'), ('O-', 'O-'),
        ('AB+', 'AB+'), ('AB-', 'AB-'),
    ]

    sender = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="broadcast_requests"
    )

    blood_group = models.CharField(max_length=3, choices=BLOOD_CHOICES)

    total_units = models.PositiveIntegerField()
    remaining_units = models.PositiveIntegerField()

    required_date = models.DateField()
    required_time = models.TimeField()

    status = models.CharField(
        max_length=15,
        choices=STATUS_CHOICES,
        default="open"
    )

    created_at = models.DateTimeField(auto_now_add=True)


class BloodBroadcastResponse(models.Model):

    RESPONSE_CHOICES = [
        ('accepted', 'Accepted'),
        ('rejected', 'Rejected'),
    ]

    request = models.ForeignKey(
        BloodBroadcastRequest,
        on_delete=models.CASCADE,
        related_name="responses"
    )

    donor = models.ForeignKey(
        User,
        on_delete=models.CASCADE
    )

    response = models.CharField(
        max_length=10,
        choices=RESPONSE_CHOICES
    )

    responded_at = models.DateTimeField(auto_now_add=True)

