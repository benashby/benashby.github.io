---
layout: post
title: "Revisiting Modern Android: Notes on Compose, Firebase, and ViewModel for a Planner App"
categories: [Android, Jetpack Compose, Firebase, ViewModel, Kotlin, Coroutines, Flows, Personal Project]
excerpt: "My notes and practical code examples from a personal daily planner project, covering Jetpack Compose for UI, Firebase for auth/data, ViewModel with StateFlow, and callbackFlow for modern Android development."
tags: [androiddev, compose, firebase, mvvm, kotlin, coroutines, stateflow, callbackflow, daily planner, app development, software engineering, android tutorial]
---

## Modern Android Development Refresh: A Personal Project Log

I've been diving back into Android development for a personal project – a simple daily planner app. It's a good excuse to refresh my knowledge on some of the more modern approaches, specifically Jetpack Compose for the UI, Firebase for straightforward auth and data persistence, and the ViewModel pattern with Kotlin Flows for managing state. This post is basically a log of my review and implementation notes.

### 1. Building UIs with Jetpack Compose

Jetpack Compose is a declarative UI toolkit. Instead of wrestling with XML and then manipulating views imperatively, you describe what the UI *should* look like for a given state. Compose handles the rendering and updates when the state changes.

**Core Ideas:**

* **Declarative:** You define UI by calling `@Composable` functions.
* **Composable Functions:** Regular Kotlin functions annotated with `@Composable` that emit UI elements. They can call other composables to build a tree.
* **State-Driven:** UI reacts to changes in state objects (like `State<T>` or `MutableState<T>`). When state used by a composable changes, that composable (and potentially its children) recomposes.

**Project Setup (`build.gradle.kts`):**

To get Compose working, you need the compiler plugin and the libraries.

```kotlin
// Top-level build.gradle.kts (or settings.gradle.kts for newer AGP versions)
// plugins {
// // ...
// alias(libs.plugins.compose.compiler) apply false // If defined in version catalog
// }

// app/build.gradle.kts
plugins {
    // ... other plugins
    alias(libs.plugins.compose.compiler) // Or: id("org.jetbrains.kotlin.plugin.compose")
}

android {
    // ...
    buildFeatures {
        compose = true
    }
    composeOptions {
        kotlinCompilerExtensionVersion = libs.versions.compose.compiler.get() // Or your specific version
    }
    // ...
}

dependencies {
    // Core Compose
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.ui.graphics)
    implementation(libs.androidx.compose.ui.tooling.preview) // Essential for previews
    implementation(libs.androidx.compose.material3)         // Material Design 3 components

    // For ViewModel integration
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    implementation(libs.androidx.lifecycle.runtime.compose) // For collectAsStateWithLifecycle

    // Navigation (if you're using Jetpack Navigation with Compose)
    // implementation(libs.androidx.navigation.compose)
    // ... other dependencies
}
````

**App Entry Point (`MainActivity.kt`):**

The `MainActivity` is where you typically host your Compose UI using `setContent`.

```kotlin
package com.example.dailyplanner // Replace with your package name

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import com.example.dailyplanner.ui.theme.DailyPlannerTheme // Your app's theme
// Import your actual main screen Composable and auth-related composables
// For example:
// import com.example.dailyplanner.ui.MainAppScreen
// import com.google.firebase.auth.FirebaseUser
// import androidx.compose.runtime.mutableStateOf // if managing user state directly in Activity

class MainActivity : ComponentActivity() {
    // Firebase Auth and CredentialManager would be initialized here as in your example
    // private lateinit var auth: FirebaseAuth
    // private lateinit var credentialManager: CredentialManager
    // private var currentUserState = mutableStateOf<FirebaseUser?>(null)


    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Initialize auth, credentialManager, and authStateListener as per your actual MainActivity.kt

        setContent {
            DailyPlannerTheme { // Apply your app's custom theme
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    // Based on your MainActivity.kt, you'd have something like:
                    // val user = currentUserState.value
                    // MainAppScreen(
                    //     currentUser = user,
                    //     onSignInInitiated = { initiateGoogleSignIn() },
                    //     onSignOut = { signOut() }
                    // )
                    // For a simpler version without full nav for this blog post:
                    // DailyPlanScreen() // Assuming DailyPlanScreen and its ViewModel handle auth state.
                }
            }
        }
    }
    // Include initiateGoogleSignIn(), handleSignInWithCredential(), authenticateWithFirebase(), signOut() methods
    // from your MainActivity.kt or a similar structure.
}
```

### 2\. Firebase Authentication

For user sign-in, Firebase Authentication is pretty straightforward. It handles passwords, social logins (like Google), etc.

**Setup:**

1.  Add Firebase to your project via the Firebase console.
2.  Place the `google-services.json` file in your `app` module's root.
3.  Add dependencies to `app/build.gradle.kts`:

<!-- end list -->

```kotlin
plugins {
    // ...
    id("com.google.gms.google-services")
}

dependencies {
    implementation(platform(libs.firebase.bom))
    implementation(libs.firebase.auth.ktx)
    // For Google Sign-In with androidx.credentials
    implementation(libs.play.services.auth) // Provides Google Sign-In SDK (though primarily for older flows, still useful for some underlying services)
    implementation(libs.androidx.credentials) // Core credential manager
    implementation(libs.androidx.credentials.play.services.auth) // For Google specific credential providers using Credential Manager
    implementation(libs.google.android.libraries.identity.googleid) // For GoogleIdTokenCredential parsing

    implementation(libs.firebase.firestore.ktx) // If using Firestore
}
```

**Google Sign-In Integration (Example directly in `MainActivity.kt`):**

My personal project integrates Google Sign-In directly within `MainActivity`. It uses the `androidx.credentials.CredentialManager` for a modern sign-in flow and updates a `MutableState` of the `FirebaseUser` to reflect the authentication status. This state then drives which UI (login or main app) is displayed.

```kotlin
package com.example.dailyplanner // Your package name

import android.os.Bundle
import android.util.Log
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.getValue // For property delegation
import androidx.compose.runtime.setValue // For property delegation
import androidx.credentials.Credential
import androidx.credentials.CredentialManager
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialRequest
import androidx.credentials.exceptions.GetCredentialCancellationException
import androidx.credentials.exceptions.GetCredentialException
import androidx.credentials.exceptions.NoCredentialException
import androidx.lifecycle.lifecycleScope
import com.example.dailyplanner.ui.MainAppScreen // Your main Composable screen for the app
import com.example.dailyplanner.ui.theme.DailyPlannerTheme
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential.Companion.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL
import com.google.android.libraries.identity.googleid.GoogleIdTokenParsingException
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.auth.GoogleAuthProvider
import com.google.firebase.auth.ktx.auth
import com.google.firebase.ktx.Firebase
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {

    private lateinit var auth: FirebaseAuth
    private lateinit var credentialManager: CredentialManager
    private var currentUserState by mutableStateOf<FirebaseUser?>(null) // State to hold the current user

    private companion object {
        private const val TAG = "MainActivityAuth"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        auth = Firebase.auth
        credentialManager = CredentialManager.create(this)

        // Listen to Firebase auth state changes
        val authStateListener = FirebaseAuth.AuthStateListener { firebaseAuth ->
            currentUserState = firebaseAuth.currentUser
            if (firebaseAuth.currentUser == null) {
                Log.d(TAG, "AuthStateListener: User signed out or not signed in.")
            } else {
                Log.d(TAG, "AuthStateListener: User signed in: ${firebaseAuth.currentUser?.uid}")
            }
        }
        auth.addAuthStateListener(authStateListener)

        // It's good practice to remove the listener when the activity is destroyed
        // However, for a single activity app, it might not be strictly necessary if auth lives with the app.
        // Consider lifecycle.addObserver for removing it in onDestroy if you have multiple activities or complex lifecycles.

        setContent {
            DailyPlannerTheme {
                val user = currentUserState // Use the state variable

                // Automatically attempt sign-in if no user is logged in and not already attempted
                if (user == null && auth.currentUser == null) {
                    LaunchedEffect(Unit) { // Keyed to Unit to run once
                        Log.d(TAG, "setContent: No current user, initiating Google Sign-In from LaunchedEffect.")
                        initiateGoogleSignIn()
                    }
                }

                MainAppScreen(
                    currentUser = user,
                    onSignInInitiated = { initiateGoogleSignIn() },
                    onSignOut = { signOut() }
                )
            }
        }
    }

    override fun onStart() {
        super.onStart()
        currentUserState = auth.currentUser // Ensure state is current onStart
        if (auth.currentUser == null) {
            Log.d(TAG, "onStart: No user detected by Firebase.")
        } else {
            Log.d(TAG, "onStart: User ${auth.currentUser?.uid} is signed in.")
        }
    }

    private fun initiateGoogleSignIn() {
        Log.d(TAG, "Initiating Google Sign-In flow.")
        val webClientId = getString(R.string.default_web_client_id) // Ensure this is in your strings.xml

        if (webClientId.isBlank() || !webClientId.endsWith(".apps.googleusercontent.com") || webClientId == "YOUR_WEB_CLIENT_ID") {
            Log.e(TAG, "default_web_client_id is not configured correctly. Value: $webClientId")
            Toast.makeText(this, "Web client ID for Google Sign-In is not configured. Check logs.", Toast.LENGTH_LONG).show()
            currentUserState = null
            return
        }

        val googleIdOption: GetGoogleIdOption = GetGoogleIdOption.Builder()
            .setFilterByAuthorizedAccounts(false)
            .setServerClientId(webClientId)
            .build()

        val request: GetCredentialRequest = GetCredentialRequest.Builder()
            .addCredentialOption(googleIdOption)
            .build()

        lifecycleScope.launch {
            try {
                Log.d(TAG, "Requesting credential from CredentialManager...")
                val result = credentialManager.getCredential(this@MainActivity, request)
                Log.d(TAG, "Credential retrieved. Handling sign-in...")
                handleSignInWithCredential(result.credential)
            } catch (e: GetCredentialException) {
                val errorMessage = when (e) {
                    is GetCredentialCancellationException -> "Sign-in cancelled."
                    is NoCredentialException -> "No Google accounts found."
                    else -> "Sign-in failed: ${e.localizedMessage ?: "Unknown credential error"}"
                }
                Log.e(TAG, "GetCredentialException: ${e.message}, Type: ${e.type}", e)
                Toast.makeText(this@MainActivity, errorMessage, Toast.LENGTH_LONG).show()
                currentUserState = null
            } catch (e: Exception) {
                Log.e(TAG, "Unexpected error during Google Sign-In: ${e.message}", e)
                Toast.makeText(this@MainActivity, "Sign-in failed: Unexpected error.", Toast.LENGTH_LONG).show()
                currentUserState = null
            }
        }
    }

    private fun handleSignInWithCredential(credential: Credential) {
        Log.d(TAG, "Handling credential of type: ${credential.type}")
        if (credential is CustomCredential && credential.type == TYPE_GOOGLE_ID_TOKEN_CREDENTIAL) {
            try {
                val googleIdTokenCredential = GoogleIdTokenCredential.createFrom(credential.data)
                val idToken = googleIdTokenCredential.idToken
                if (idToken != null) {
                    Log.d(TAG, "Google ID Token obtained. Authenticating with Firebase...")
                    authenticateWithFirebase(idToken)
                } else {
                    Log.e(TAG, "Google ID Token is null after parsing CustomCredential.")
                    Toast.makeText(this, "Failed to get Google ID Token.", Toast.LENGTH_LONG).show()
                    currentUserState = null
                }
            } catch (e: GoogleIdTokenParsingException) {
                Log.e(TAG, "Failed to parse Google ID Token.", e)
                Toast.makeText(this, "Error parsing Google sign-in data.", Toast.LENGTH_LONG).show()
                currentUserState = null
            } catch (e: Exception) {
                Log.e(TAG, "Error processing Google ID Token: ${e.message}", e)
                Toast.makeText(this, "An unexpected error occurred.", Toast.LENGTH_LONG).show()
                currentUserState = null
            }
        } else {
            Log.w(TAG, "Received unexpected credential type: ${credential.type}.")
            Toast.makeText(this, "Unexpected credential type.", Toast.LENGTH_LONG).show()
            currentUserState = null
        }
    }

    private fun authenticateWithFirebase(idToken: String) {
        val firebaseCredential = GoogleAuthProvider.getCredential(idToken, null)
        auth.signInWithCredential(firebaseCredential)
            .addOnCompleteListener(this) { task ->
                if (task.isSuccessful) {
                    Log.d(TAG, "Firebase signInWithCredential success. User: ${auth.currentUser?.uid}")
                    // AuthStateListener will update currentUserState
                    Toast.makeText(this, "Signed in successfully!", Toast.LENGTH_SHORT).show()
                } else {
                    Log.w(TAG, "Firebase signInWithCredential failure.", task.exception)
                    Toast.makeText(this, "Firebase auth failed: ${task.exception?.message}", Toast.LENGTH_LONG).show()
                    currentUserState = null
                }
            }
    }

    private fun signOut() {
        Log.d(TAG, "Signing out user...")
        auth.signOut()
        // AuthStateListener will update currentUserState
        Toast.makeText(this@MainActivity, "Signed out.", Toast.LENGTH_SHORT).show()
        // Optionally, you might want to trigger navigation to a login screen or clear user-specific data.
        // The AuthStateListener handling currentUserState should drive the UI to the appropriate state.
    }
}

// Dummy MainAppScreen Composable for illustration
// In your real app, this would be your main navigation host or screen
@Composable
fun MainAppScreen(
    currentUser: FirebaseUser?,
    onSignInInitiated: () -> Unit,
    onSignOut: () -> Unit
    // Add DailyPlanViewModel or other dependencies if needed at this level
) {
    if (currentUser == null) {
        // Show LoginScreen or similar
        Column(
            modifier = Modifier.fillMaxSize(),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text("Please sign in to continue.")
            Spacer(modifier = Modifier.height(16.dp))
            Button(onClick = onSignInInitiated) {
                Text("Sign in with Google")
            }
        }
    } else {
        // User is signed in, show the main app content
        // This is where you'd put your DailyPlanScreen or NavigationHost
        // For the blog post, we'll assume DailyPlanScreen is shown and gets the userId
        // val dailyPlanViewModel: DailyPlanViewModel = viewModel(
        //     factory = DailyPlanViewModel.Factory(
        //         repository = DailyPlanRepository(FirebaseFirestore.getInstance()), // Provide actual repo
        //         userId = currentUser.uid // Pass the current user's ID
        //     )
        // )
        // DailyPlanScreen(viewModel = dailyPlanViewModel)

        // A simpler placeholder for now:
        Column(
             modifier = Modifier.fillMaxSize().padding(16.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text("Welcome, ${currentUser.displayName ?: currentUser.email ?: "User"}!")
            Text("User ID: ${currentUser.uid}")
            Spacer(modifier = Modifier.height(20.dp))
            Button(onClick = onSignOut) {
                Text("Sign Out")
            }
            Spacer(modifier = Modifier.height(20.dp))
            Text("Your Daily Planner App Content Would Go Here.")
            // Example: Instantiate and call DailyPlanScreen, passing the current user's ID to its ViewModel.
        }
    }
}
```

Your `R.string.default_web_client_id` is obtained from the `google-services.json` file (or Firebase console: Project Settings \> General \> Your Apps \> Web SDK configuration snippet, it's the `authDomain`'s project ID or the one specified under Authentication \> Sign-in method \> Google \> Web client ID).

### 3\. ViewModel and Reactive State Management with Flows

`ViewModel` is for holding and managing UI-related data in a way that respects the Android lifecycle (e.g., surviving screen rotations). `StateFlow` from Kotlin Coroutines is a great fit for exposing state that Compose can observe.

**Key Ideas:**

* **ViewModel:** Owns UI state and business logic. Doesn't know about specific UI components.
* **StateFlow:** A hot flow that holds a value and emits updates. Ideal for representing screen state.
* **Repository:** Abstracts data sources (network, local DB). ViewModels talk to repositories.

**Understanding `callbackFlow`**

In the `DailyPlanRepository`, I used `callbackFlow`. This is a flow builder that's super useful for converting callback-based APIs into Kotlin Flows. Many older Android APIs or third-party libraries (like Firebase's `addSnapshotListener`) use callbacks. `callbackFlow` lets you bridge them to the reactive world of Flows.

**Why use `callbackFlow`?**

* **Modernize old APIs:** You can wrap APIs that rely on listeners (e.g., location updates, sensor data, Firebase real-time updates) into a Flow, making them easier to use with coroutines and structured concurrency.
* **Lifecycle Management:** The `awaitClose { ... }` block is crucial. It's executed when the collecting coroutine is cancelled. This is where you unregister listeners or clean up resources to prevent memory leaks.
* **Backpressure:** `trySend()` (or `trySendBlocking`) is used to emit values. If the channel buffer (if configured) is full, `trySend` will fail to send (returning `false` or throwing for `trySendBlocking` if the channel is closed/full and configured to throw). For listener patterns where data comes infrequently, this is usually fine.

**How `callbackFlow` Works (Conceptual Example):**

Imagine you have an API that gives you updates via a listener:

```kotlin
// Legacy API
interface DataListener {
    fun onDataReceived(data: String)
    fun onError(e: Exception)
}

class LegacyDataSource {
    private var listener: DataListener? = null
    fun register(listener: DataListener) { this.listener = listener /* ... starts emitting data ... */ }
    fun unregister() { this.listener = null /* ... stops emitting data ... */ }

    // Method to simulate data coming in
    fun simulateData(data: String) {
        listener?.onDataReceived(data)
    }
    fun simulateError(e: Exception) {
        listener?.onError(e)
    }
}
```

You can wrap this with `callbackFlow`:

```kotlin
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.runBlocking // For example only

fun getDataSourceFlow(dataSource: LegacyDataSource): Flow<String> = callbackFlow {
    val listener = object : DataListener {
        override fun onDataReceived(data: String) {
            val offerResult = trySend(data) // Send data into the flow
            if (!offerResult.isSuccess) {
                 // Handle failure to send, e.g. log it, or if critical, close the flow
                 println("Failed to send data to flow: $data. Channel full or closed.")
            }
        }

        override fun onError(e: Exception) {
            close(e) // Close the flow with an error
        }
    }

    dataSource.register(listener) // Register the callback

    // This block is called when the flow is cancelled or closed by the consumer or an error
    awaitClose {
        dataSource.unregister() // Clean up: unregister the callback
        println("Flow closed, listener unregistered")
    }
}

// Example Usage (not in ViewModel, just for illustration)
// fun main() = runBlocking {
//     val legacyDataSource = LegacyDataSource()
//     val dataFlow = getDataSourceFlow(legacyDataSource)
//
//     val job = launch {
//         dataFlow
//             .catch { e -> println("Collected error: ${e.message}") }
//             .collect { data -> println("Collected: $data") }
//     }
//
//     legacyDataSource.simulateData("Event 1")
//     delay(100)
//     legacyDataSource.simulateData("Event 2")
//     delay(100)
//     legacyDataSource.simulateError(Exception("Something went wrong"))
//
//     job.join()
// }
```

In the `DailyPlanRepository` example, `addSnapshotListener` from Firestore is the callback-based API. `callbackFlow` wraps it, `trySend` pushes new snapshots (or null/errors) into the flow, and `awaitClose` removes the listener when the flow is no longer collected.

**Enhanced `DailyPlanViewModel.kt`:**

This ViewModel will manage the state for our daily planner screen. Remember to pass the `userId` from the `Activity` (after successful login) to this ViewModel, likely via its factory.

```kotlin
package com.example.dailyplanner.ui.dailyplan // Replace with your package

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.example.dailyplanner.data.model.DailyPlan
import com.example.dailyplanner.data.model.TaskItem
import com.example.dailyplanner.data.model.Priority
import com.example.dailyplanner.data.repository.DailyPlanRepository
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.util.UUID // For generating task IDs locally if needed

// --- Data Models (usually in a data.model package) ---
// Ensure these are defined, e.g.:
// data class TaskItem(
//     val id: String = UUID.randomUUID().toString(),
//     val title: String,
//     var description: String? = null,
//     var isCompleted: Boolean = false,
//     var priority: Priority = Priority.MEDIUM,
//     // var dueDate: LocalDate? = null // Consider adding if needed
// )
//
// enum class Priority { HIGH, MEDIUM, LOW }
//
// data class DailyPlan(
//     val date: String = LocalDate.now().toString(), // Using ISO-8601 date string as ID
//     var tasks: List<TaskItem> = emptyList(),
//     val userId: String? = null // Important for user-specific plans
// )
// --- End Data Models ---


// Sealed interface for UI State
sealed interface DailyPlanUiState {
    data object Loading : DailyPlanUiState
    data class Success(
        val currentPlan: DailyPlan, // The full plan for the date
        val displayedTasks: List<TaskItem>, // Filtered/searched tasks
        val selectedDate: LocalDate,
        val searchQuery: String = "",
        val filter: TaskFilter = TaskFilter.ALL
    ) : DailyPlanUiState
    data class Error(val message: String) : DailyPlanUiState
}

enum class TaskFilter { ALL, ACTIVE, COMPLETED }

class DailyPlanViewModel(
    private val repository: DailyPlanRepository,
    private val userId: String // User ID is now non-nullable, assume user is logged in
) : ViewModel() {

    private val _selectedDate = MutableStateFlow(LocalDate.now())
    private val _searchQuery = MutableStateFlow("")
    private val _filter = MutableStateFlow(TaskFilter.ALL)

    // This is the main state holder exposed to the UI
    val uiState: StateFlow<DailyPlanUiState> =
        combine(
            _selectedDate,
            _searchQuery,
            _filter
        ) { date, query, currentFilter -> Triple(date, query, currentFilter) }
        .flatMapLatest { (date, query, currentFilter) ->
            repository.getDailyPlanForDateStream(userId, date.toString())
                .map { result ->
                    result.fold(
                        onSuccess = { plan ->
                            val actualPlan = plan ?: DailyPlan(date = date.toString(), userId = userId, tasks = emptyList())
                            val filteredTasks = filterAndSearchTasks(actualPlan.tasks, query, currentFilter)
                            DailyPlanUiState.Success(
                                currentPlan = actualPlan,
                                displayedTasks = filteredTasks,
                                selectedDate = date,
                                searchQuery = query,
                                filter = currentFilter
                            )
                        },
                        onFailure = { exception ->
                            DailyPlanUiState.Error("Failed to load plan: ${exception.localizedMessage}")
                        }
                    )
                }
        }
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = DailyPlanUiState.Loading
        )

    private fun filterAndSearchTasks(tasks: List<TaskItem>, query: String, filter: TaskFilter): List<TaskItem> {
        val queryFiltered = if (query.isBlank()) {
            tasks
        } else {
            tasks.filter {
                it.title.contains(query, ignoreCase = true) ||
                it.description?.contains(query, ignoreCase = true) == true
            }
        }
        return when (filter) {
            TaskFilter.ALL -> queryFiltered
            TaskFilter.ACTIVE -> queryFiltered.filter { !it.isCompleted }
            TaskFilter.COMPLETED -> queryFiltered.filter { it.isCompleted }
        }
    }

    fun selectDate(date: LocalDate) {
        _selectedDate.value = date
    }

    fun setSearchQuery(query: String) {
        _searchQuery.value = query
    }

    fun setFilter(filter: TaskFilter) {
        _filter.value = filter
    }

    fun addTask(title: String, description: String?, priority: Priority) {
        viewModelScope.launch {
            val currentState = uiState.value
            if (currentState is DailyPlanUiState.Success) {
                val newTask = TaskItem(id = UUID.randomUUID().toString(), title = title, description = description, priority = priority)
                // Optimistic update: Modify local state first, then save.
                // Firestore listener will eventually provide the source of truth.
                val updatedTasks = currentState.currentPlan.tasks + newTask
                val updatedPlan = currentState.currentPlan.copy(tasks = updatedTasks)

                // Update the local state immediately for responsiveness (optional, but good UX)
                // _uiState.value = currentState.copy(
                //     currentPlan = updatedPlan,
                //     displayedTasks = filterAndSearchTasks(updatedPlan.tasks, currentState.searchQuery, currentState.filter)
                // )

                repository.saveDailyPlan(updatedPlan).onFailure { e ->
                    // Handle save error: revert optimistic update or show error message
                    Log.e("DailyPlanVM", "Failed to save task: ${e.localizedMessage}")
                    // Potentially emit an error state or a snackbar message
                }
                // The combine flow observing the repository will eventually update the UI with persisted data.
            } else {
                Log.w("DailyPlanVM", "Cannot add task, UI state is not Success: $currentState")
            }
        }
    }

    fun toggleTaskCompletion(taskId: String) {
        viewModelScope.launch {
            val currentState = uiState.value
            if (currentState is DailyPlanUiState.Success) {
                val planToUpdate = currentState.currentPlan
                val updatedTasks = planToUpdate.tasks.map {
                    if (it.id == taskId) it.copy(isCompleted = !it.isCompleted) else it
                }
                val updatedPlan = planToUpdate.copy(tasks = updatedTasks)
                repository.saveDailyPlan(updatedPlan).onFailure { e ->
                     Log.e("DailyPlanVM", "Failed to toggle task completion: ${e.localizedMessage}")
                }
            }
        }
    }

    fun updateTaskPriority(taskId: String, newPriority: Priority) {
        viewModelScope.launch {
            val currentState = uiState.value
            if (currentState is DailyPlanUiState.Success) {
                val planToUpdate = currentState.currentPlan
                val updatedTasks = planToUpdate.tasks.map {
                    if (it.id == taskId) it.copy(priority = newPriority) else it
                }
                val updatedPlan = planToUpdate.copy(tasks = updatedTasks)
                repository.saveDailyPlan(updatedPlan).onFailure { e ->
                    Log.e("DailyPlanVM", "Failed to update task priority: ${e.localizedMessage}")
                }
            }
        }
    }

    fun deleteTask(taskId: String) {
        viewModelScope.launch {
            val currentState = uiState.value
            if (currentState is DailyPlanUiState.Success) {
                val planToUpdate = currentState.currentPlan
                val updatedTasks = planToUpdate.tasks.filterNot { it.id == taskId }
                val updatedPlan = planToUpdate.copy(tasks = updatedTasks)
                repository.saveDailyPlan(updatedPlan).onFailure { e ->
                     Log.e("DailyPlanVM", "Failed to delete task: ${e.localizedMessage}")
                }
            }
        }
    }

    // Factory for creating ViewModel with dependencies
    companion object {
        fun Factory(repository: DailyPlanRepository, userId: String): ViewModelProvider.Factory =
            object : ViewModelProvider.Factory {
                @Suppress("UNCHECKED_CAST")
                override fun <T : ViewModel> create(modelClass: Class<T>): T {
                    if (modelClass.isAssignableFrom(DailyPlanViewModel::class.java)) {
                        return DailyPlanViewModel(repository, userId) as T
                    }
                    throw IllegalArgumentException("Unknown ViewModel class: ${modelClass.name}")
                }
            }
    }
}
```

**Updated `DailyPlanRepository.kt`:**

The repository needs the `userId` to fetch and save user-specific plans. It's structured under `users/{userId}/dailyPlans/{dateString}`.

```kotlin
package com.example.dailyplanner.data.repository // Replace with your package

import android.util.Log
import com.example.dailyplanner.data.model.DailyPlan
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await

class DailyPlanRepository(private val firestore: FirebaseFirestore) {

    fun getDailyPlanForDateStream(userId: String, dateString: String): Flow<Result<DailyPlan?>> = callbackFlow {
        Log.d("Repository", "Fetching plan for user: $userId, date: $dateString")
        if (userId.isBlank()) {
            trySend(Result.failure(IllegalArgumentException("User ID cannot be blank.")))
            close()
            return@callbackFlow
        }

        val docRef = firestore.collection("users").document(userId)
                            .collection("dailyPlans").document(dateString)

        val listenerRegistration: ListenerRegistration = docRef.addSnapshotListener { snapshot, error ->
            if (error != null) {
                Log.e("Repository", "Listen failed for $dateString", error)
                trySend(Result.failure(error))
                // close(error) // Optionally close flow on error. For snapshot listeners, you might want to keep it open for retries.
                return@addSnapshotListener
            }
            if (snapshot != null && snapshot.exists()) {
                Log.d("Repository", "Plan exists for $dateString. Data: ${snapshot.data}")
                trySend(Result.success(snapshot.toObject(DailyPlan::class.java)))
            } else {
                Log.d("Repository", "No plan found for $dateString. Sending success with null.")
                trySend(Result.success(null)) // Document doesn't exist
            }
        }
        awaitClose {
            Log.d("Repository", "Removing listener for user $userId, date $dateString")
            listenerRegistration.remove()
        }
    }

    suspend fun saveDailyPlan(dailyPlan: DailyPlan): Result<Unit> {
        return try {
            if (dailyPlan.userId.isNullOrBlank()) {
                return Result.failure(IllegalArgumentException("User ID cannot be null or blank for saving a plan."))
            }
            Log.d("Repository", "Saving plan for user: ${dailyPlan.userId}, date: ${dailyPlan.date}")
            firestore.collection("users").document(dailyPlan.userId)
                     .collection("dailyPlans").document(dailyPlan.date)
                     .set(dailyPlan) // set() will overwrite or create the document
                     .await()
            Log.d("Repository", "Plan saved successfully for ${dailyPlan.date}")
            Result.success(Unit)
        } catch (e: Exception) {
            Log.e("Repository", "Error saving plan for ${dailyPlan.date}", e)
            Result.failure(e)
        }
    }
}
```

### 4\. Enhanced Composable UI (`DailyPlanScreen.kt` and components)

The UI will observe the `uiState` from the `DailyPlanViewModel`. When using a `ViewModel` that requires parameters (like `userId`), ensure you provide a `ViewModelProvider.Factory`.

**`DailyPlanScreen.kt` (Main Screen Composable):**

```kotlin
package com.example.dailyplanner.ui.dailyplan // Replace with your package

import android.app.DatePickerDialog
import android.widget.DatePicker
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.outlined.ArrowDropDown
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.dailyplanner.data.model.DailyPlan
import com.example.dailyplanner.data.model.TaskItem
import com.example.dailyplanner.data.model.Priority
import com.example.dailyplanner.data.repository.DailyPlanRepository
import com.example.dailyplanner.ui.theme.DailyPlannerTheme
import com.google.firebase.firestore.FirebaseFirestore
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle
import java.util.Calendar
import java.util.UUID

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DailyPlanScreen(
    viewModel: DailyPlanViewModel // Injected or obtained via NavHost, using factory
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    var showAddTaskDialog by remember { mutableStateOf(false) }
    var showDatePickerDialog by remember { mutableStateOf(false) }

    val context = LocalContext.current

    Scaffold(
        topBar = {
            val titleDate = (uiState as? DailyPlanUiState.Success)?.selectedDate
                            ?: LocalDate.now()
            CenterAlignedTopAppBar(
                title = {
                    Text("Plan for ${titleDate.format(DateTimeFormatter.ofLocalizedDate(FormatStyle.MEDIUM))}")
                },
                actions = {
                    IconButton(onClick = { showDatePickerDialog = true }) {
                        Icon(Icons.Filled.DateRange, contentDescription = "Select Date")
                    }
                }
            )
        },
        floatingActionButton = {
            FloatingActionButton(onClick = { showAddTaskDialog = true }) {
                Icon(Icons.Filled.Add, contentDescription = "Add Task")
            }
        },
        modifier = Modifier.fillMaxSize()
    ) { paddingValues ->
        Box(modifier = Modifier.padding(paddingValues).fillMaxSize()) {
            when (val state = uiState) {
                is DailyPlanUiState.Loading -> {
                    CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
                }
                is DailyPlanUiState.Success -> {
                    DailyPlanContent(
                        tasks = state.displayedTasks, // Use displayedTasks from Success state
                        searchQuery = state.searchQuery,
                        currentFilter = state.filter,
                        onSearchQueryChange = { viewModel.setSearchQuery(it) },
                        onFilterChange = { viewModel.setFilter(it) },
                        onToggleTask = { taskId -> viewModel.toggleTaskCompletion(taskId) },
                        onDeleteTask = { taskId -> viewModel.deleteTask(taskId) },
                        onPriorityChange = { taskId, priority -> viewModel.updateTaskPriority(taskId, priority) }
                    )
                }
                is DailyPlanUiState.Error -> {
                    Text(
                        text = "Error: ${state.message}",
                        color = MaterialTheme.colorScheme.error,
                        modifier = Modifier.align(Alignment.Center).padding(16.dp)
                    )
                }
            }
        }
    }

    if (showAddTaskDialog) {
        AddTaskDialog(
            onDismiss = { showAddTaskDialog = false },
            onAddTask = { title, description, priority ->
                viewModel.addTask(title, description, priority)
                showAddTaskDialog = false
            }
        )
    }

    if (showDatePickerDialog) {
        val currentSelectedDate = (uiState as? DailyPlanUiState.Success)?.selectedDate ?: LocalDate.now()
        val calendar = Calendar.getInstance().apply {
            set(currentSelectedDate.year, currentSelectedDate.monthValue - 1, currentSelectedDate.dayOfMonth)
        }
        DatePickerDialog(
            context,
            { _: DatePicker, year: Int, month: Int, dayOfMonth: Int ->
                viewModel.selectDate(LocalDate.of(year, month + 1, dayOfMonth))
                showDatePickerDialog = false
            },
            calendar.get(Calendar.YEAR),
            calendar.get(Calendar.MONTH),
            calendar.get(Calendar.DAY_OF_MONTH)
        ).show()
        // Ensure dialog is dismissed if user clicks outside or back button
        // This is handled by the Dialog itself, but if it were a Compose dialog,
        // onDismissRequest would be used. For Android Dialog, setting showDatePickerDialog = false
        // in onDateSet and onDismiss (if it had one) is key.
        // To prevent recomposition loop, ensure DatePickerDialog is not directly in Composable body
        // The `showDatePickerDialog` state controls its visibility.
    }
}

@Composable
fun DailyPlanContent(
    tasks: List<TaskItem>, // Now takes the filtered list directly
    searchQuery: String,
    currentFilter: TaskFilter,
    onSearchQueryChange: (String) -> Unit,
    onFilterChange: (TaskFilter) -> Unit,
    onToggleTask: (String) -> Unit,
    onDeleteTask: (String) -> Unit,
    onPriorityChange: (String, Priority) -> Unit,
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier.padding(16.dp).fillMaxSize()) {
        SearchBar(
            query = searchQuery,
            onQueryChange = onSearchQueryChange,
            modifier = Modifier.fillMaxWidth()
        )
        Spacer(modifier = Modifier.height(8.dp))
        TaskFilterChips(
            selectedFilter = currentFilter,
            onFilterSelected = onFilterChange,
            modifier = Modifier.fillMaxWidth()
        )
        Spacer(modifier = Modifier.height(16.dp))

        if (tasks.isEmpty()) {
            Box(modifier = Modifier.weight(1f).fillMaxWidth(), contentAlignment = Alignment.Center) {
                 if (searchQuery.isNotBlank() || currentFilter != TaskFilter.ALL) {
                    Text("No tasks match your current search/filter.")
                } else {
                    Text("No tasks for this day yet. Add some!")
                }
            }
        } else {
            TaskList(
                tasks = tasks,
                onToggleTask = onToggleTask,
                onDeleteTask = onDeleteTask,
                onPriorityChange = onPriorityChange
            )
        }
    }
}

@Composable
fun SearchBar(query: String, onQueryChange: (String) -> Unit, modifier: Modifier = Modifier) {
    OutlinedTextField(
        value = query,
        onValueChange = onQueryChange,
        label = { Text("Search tasks") },
        modifier = modifier,
        singleLine = true
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TaskFilterChips(selectedFilter: TaskFilter, onFilterSelected: (TaskFilter) -> Unit, modifier: Modifier = Modifier) {
    Row(modifier = modifier, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        TaskFilter.values().forEach { filter ->
            FilterChip(
                selected = selectedFilter == filter,
                onClick = { onFilterSelected(filter) },
                label = { Text(filter.name.lowercase().replaceFirstChar { it.titlecase() }) }
            )
        }
    }
}

@Composable
fun TaskList(
    tasks: List<TaskItem>,
    onToggleTask: (String) -> Unit,
    onDeleteTask: (String) -> Unit,
    onPriorityChange: (String, Priority) -> Unit,
    modifier: Modifier = Modifier
) {
    LazyColumn(modifier = modifier) {
        items(tasks, key = { it.id }) { task ->
            TaskRow(
                task = task,
                onToggle = { onToggleTask(task.id) },
                onDelete = { onDeleteTask(task.id) },
                onPriorityChange = { newPriority -> onPriorityChange(task.id, newPriority) }
            )
        }
    }
}

@Composable
fun TaskRow(
    task: TaskItem,
    onToggle: () -> Unit,
    onDelete: () -> Unit,
    onPriorityChange: (Priority) -> Unit,
    modifier: Modifier = Modifier
) {
    var showPriorityMenu by remember { mutableStateOf(false) }

    Card(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp)
            .clickable { onToggle() },
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Row(
            modifier = Modifier
                .padding(horizontal = 12.dp, vertical = 8.dp)
                .fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Checkbox(
                checked = task.isCompleted,
                onCheckedChange = { onToggle() }
            )
            Spacer(modifier = Modifier.width(10.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = task.title,
                    style = MaterialTheme.typography.titleMedium,
                    textDecoration = if (task.isCompleted) TextDecoration.LineThrough else TextDecoration.None,
                    color = if (task.isCompleted) MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f) else LocalContentColor.current
                )
                if (!task.description.isNullOrBlank()) {
                    Text(
                        text = task.description!!,
                        style = MaterialTheme.typography.bodySmall,
                        textDecoration = if (task.isCompleted) TextDecoration.LineThrough else TextDecoration.None,
                        color = if (task.isCompleted) MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f) else LocalContentColor.current.copy(alpha = 0.7f)
                    )
                }
            }
            Spacer(modifier = Modifier.width(8.dp))

            Box {
                Button(
                    onClick = { showPriorityMenu = true },
                    colors = ButtonDefaults.buttonColors(
                        containerColor = priorityContainerColor(task.priority),
                        contentColor = priorityContentColor(task.priority)
                    ),
                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 4.dp),
                    modifier = Modifier.height(36.dp)
                ) {
                    Text(task.priority.name.first().toString(), style = MaterialTheme.typography.labelSmall)
                    Icon(Icons.Outlined.ArrowDropDown, contentDescription = "Change priority", Modifier.size(18.dp))
                }
                DropdownMenu(
                    expanded = showPriorityMenu,
                    onDismissRequest = { showPriorityMenu = false }
                ) {
                    Priority.values().forEach { priority ->
                        DropdownMenuItem(
                            text = { Text(priority.name) },
                            onClick = {
                                onPriorityChange(priority)
                                showPriorityMenu = false
                            }
                        )
                    }
                }
            }

            IconButton(onClick = onDelete) {
                Icon(Icons.Filled.Delete, contentDescription = "Delete Task", tint = MaterialTheme.colorScheme.error)
            }
        }
    }
}

@Composable
fun priorityContainerColor(priority: Priority): Color {
    return when (priority) {
        Priority.HIGH -> MaterialTheme.colorScheme.errorContainer.copy(alpha = 0.5f)
        Priority.MEDIUM -> MaterialTheme.colorScheme.tertiaryContainer.copy(alpha = 0.5f)
        Priority.LOW -> MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
    }
}
@Composable
fun priorityContentColor(priority: Priority): Color {
     return when (priority) {
        Priority.HIGH -> MaterialTheme.colorScheme.onErrorContainer
        Priority.MEDIUM -> MaterialTheme.colorScheme.onTertiaryContainer
        Priority.LOW -> MaterialTheme.colorScheme.onPrimaryContainer
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddTaskDialog(
    onDismiss: () -> Unit,
    onAddTask: (title: String, description: String?, priority: Priority) -> Unit
) {
    var title by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }
    var priority by remember { mutableStateOf(Priority.MEDIUM) }
    var showPriorityMenu by remember { mutableStateOf(false) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Add New Task") },
        text = {
            Column {
                OutlinedTextField(
                    value = title,
                    onValueChange = { title = it },
                    label = { Text("Title") },
                    isError = title.isBlank() // Basic validation
                )
                Spacer(modifier = Modifier.height(8.dp))
                OutlinedTextField(
                    value = description,
                    onValueChange = { description = it },
                    label = { Text("Description (Optional)") }
                )
                Spacer(modifier = Modifier.height(8.dp))
                Box {
                     OutlinedButton(onClick = { showPriorityMenu = true }) {
                        Text("Priority: ${priority.name}")
                        Icon(Icons.Outlined.ArrowDropDown, "Select Priority")
                    }
                    DropdownMenu(expanded = showPriorityMenu, onDismissRequest = { showPriorityMenu = false }) {
                        Priority.values().forEach { p ->
                            DropdownMenuItem(text = {Text(p.name)}, onClick = { priority = p; showPriorityMenu = false })
                        }
                    }
                }
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    if (title.isNotBlank()) {
                        onAddTask(title, description.ifBlank { null }, priority)
                    }
                },
                enabled = title.isNotBlank()
            ) {
                Text("Add")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

@Preview(showBackground = true, widthDp = 380)
@Composable
fun DailyPlanScreenContentPreview() {
    val sampleTasks = listOf(
        TaskItem(id = "1", title = "Morning Standup", description = "Team sync meeting", isCompleted = true, priority = Priority.HIGH),
        TaskItem(id = "2", title = "Code Review", description = "Review PR #123 for feature X", priority = Priority.MEDIUM),
        TaskItem(id = "3", title = "Work on feature Y - a very long task title that might wrap around to multiple lines to check UI", isCompleted = false, priority = Priority.LOW)
    )
    DailyPlannerTheme {
         DailyPlanContent(
             tasks = sampleTasks,
             searchQuery = "",
             currentFilter = TaskFilter.ALL,
             onSearchQueryChange = {},
             onFilterChange = {},
             onToggleTask = {},
             onDeleteTask = {},
             onPriorityChange = {_,_ ->}
         )
    }
}

@Preview(showBackground = true)
@Composable
fun AddTaskDialogPreview() {
    DailyPlannerTheme {
        AddTaskDialog(onDismiss = {}, onAddTask = {_,_,_ ->})
    }
}
```

### Conclusion 

Refreshing these concepts for my planner app has been a good exercise.

* **Jetpack Compose** definitely makes UI development more intuitive once you grasp the declarative mindset and state management. Breaking UI into small, manageable composables is key.
* **Firebase Auth** with `androidx.credentials` is the modern way for Google Sign-In, providing a streamlined user experience. Managing user state in the `Activity` and passing it down or making it accessible to ViewModels works well.
* **ViewModel with StateFlow** provides a solid pattern for managing UI state reactively. `collectAsStateWithLifecycle` is essential for Compose to observe these flows correctly and avoid issues with background collection. The `combine` operator is powerful for creating a single UI state from multiple sources.
* **`callbackFlow`** is a valuable tool for bridging older callback-based APIs (like Firestore's snapshot listeners) into the structured concurrency world of Kotlin Flows, ensuring resource cleanup with `awaitClose`.

This combination feels robust for building modern Android apps. The planner project, while focused on a single feature for this review, demonstrates how these core components fit together. For a real app, ensuring the `userId` is correctly propagated from the authenticated user to the `DailyPlanViewModel` (e.g., via its factory) is crucial for loading and saving user-specific data.