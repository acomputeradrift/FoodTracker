//
//  MealTableViewController.swift
//  FoodTracker
//
//  Created by Jamie on 2018-09-09.
//  Copyright © 2018 Jamie. All rights reserved.
//

import UIKit
import os.log
import Firebase
import FirebaseAuth
import FirebaseDatabase


class MealTableViewController: UITableViewController {
    
    //MARK: Properties
    
    var meals = [Meal]()
    weak var actionToEnable : UIAlertAction?
    var mainUser : User?
    var currentUser: String?
    var ref: DatabaseReference!
    
    @IBOutlet weak var loginName: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        signOut()
        welcome()
        // Use the edit button item provided by the table view controller.
        //navigationItem.leftBarButtonItem = editButtonItem
        if let savedMeals = loadMeals() {
            meals += savedMeals
        }else {
            loadSampleMeals()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return meals.count
    }
    
    //MARK: Actions
    
    @IBAction func unwindToMealList(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? MealViewController, let meal = sourceViewController.meal {
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                // Update an existing meal.
                meals[selectedIndexPath.row] = meal
                tableView.reloadRows(at: [selectedIndexPath], with: .none)
            }else {
                // Add a new meal.
                let newIndexPath = IndexPath(row: meals.count, section: 0)
                
                meals.append(meal)
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            }
            // Save the meals.
            saveMeals()
        }
    }
    
    //MARK: Private Methods
    
    private func loadSampleMeals() {
        let photo1 = UIImage(named: "meal1")
        let photo2 = UIImage(named: "meal2")
        let photo3 = UIImage(named: "meal3")
        guard let meal1 = Meal(name: "Caprese Salad", photo: photo1, rating: 4) else {
            fatalError("Unable to instantiate meal1")
        }
        
        guard let meal2 = Meal(name: "Chicken and Potatoes", photo: photo2, rating: 5) else {
            fatalError("Unable to instantiate meal2")
        }
        
        guard let meal3 = Meal(name: "Pasta with Meatballs", photo: photo3, rating: 3) else {
            fatalError("Unable to instantiate meal2")
        }
        meals += [meal1, meal2, meal3]
    }
    
    private func saveMeals() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(meals, toFile: Meal.ArchiveURL.path)
        if isSuccessfulSave {
            os_log("Meals successfully saved.", log: OSLog.default, type: .debug)
        } else {
            os_log("Failed to save meals...", log: OSLog.default, type: .error)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "MealTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? MealTableViewCell  else {
            fatalError("The dequeued cell is not an instance of MealTableViewCell.")
        }
        // Fetches the appropriate meal for the data source layout.
        let meal = meals[indexPath.row]
        cell.nameLabel.text = meal.name
        cell.photoImageView.image = meal.photo
        cell.ratingControl.rating = meal.rating
        return cell
    }
    
//    //Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            meals.remove(at: indexPath.row)
            saveMeals()
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        switch(segue.identifier ?? "") {
        case "AddItem":
            os_log("Adding a new meal.", log: OSLog.default, type: .debug)
        case "ShowDetail":
            guard let mealDetailViewController = segue.destination as? MealViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            guard let selectedMealCell = sender as? MealTableViewCell else {
                fatalError("Unexpected sender: \(sender ?? "No Meal")")
            }
            
            guard let indexPath = tableView.indexPath(for: selectedMealCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            
            let selectedMeal = meals[indexPath.row]
            mealDetailViewController.meal = selectedMeal
        default:
            fatalError("Unexpected Segue Identifier; \(segue.identifier ?? "No segue identifier")")
        }
    }
    
    private func loadMeals() -> [Meal]? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: Meal.ArchiveURL.path) as? [Meal]
    }
    
    // MARK: - Welcome Screen
    
    func welcome(){
        var myAlert = UIAlertController()
        myAlert = UIAlertController(title: "Welcome to FoodTracker!", message: "Please sign in or create an account.", preferredStyle: .alert)
        let signInAction = UIAlertAction(title: "Sign In", style: .default, handler: { (alert) -> Void in
            self.userSignIn()
        })
        let signUpAction = UIAlertAction(title: "Create Account", style: .default, handler: { (alert) -> Void in
            self.userSignUp()
        })
        myAlert.addAction(signInAction)
        myAlert.addAction(signUpAction)
        self.present(myAlert, animated: true, completion: nil)
    }
    
    // MARK: - User Sign Up
    func userSignUp () {
        
        var myAlert = UIAlertController()
        myAlert = UIAlertController(title: "Create Account", message: "Please enter your email and password for your new account:", preferredStyle: .alert)
        myAlert.addTextField { (textFields) in
            textFields.placeholder = "enter email"
        }
        myAlert.addTextField { (textFields) in
            textFields.placeholder = "enter password"
            textFields.isSecureTextEntry = true
        }
        let cancel = UIAlertAction(title: "Cancel", style: .destructive, handler: { (action) -> Void in })
        let createAcountAction = UIAlertAction(title: "Create Account", style: .default, handler: { (alert) -> Void in
            guard let email = myAlert.textFields![0].text as String? else{
                print("That email is not good")
                return
            }
            guard let password = myAlert.textFields![1].text as String? else{
                print("That password is not good")
                return
            }
            self.ref = Database.database().reference()
            Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
                // ...
                guard let user = authResult?.user else { return }
                self.currentUser = user.email
                self.loginName.title = self.currentUser
                self.signUpConfirm()
            }
            
        })
        
        myAlert.addAction(createAcountAction)
        myAlert.addAction(cancel)
        self.present(myAlert, animated: true, completion: nil)
    }
    
    func signUpConfirm(){
        var savedAlert = UIAlertController()
        savedAlert = UIAlertController(title: "Creating account...", message: "", preferredStyle: .alert)
        self.present(savedAlert, animated: true, completion:nil )
        let when = DispatchTime.now() + 2
        DispatchQueue.main.asyncAfter(deadline: when){
            savedAlert.dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: - User Sign In
    
    func userSignIn () {
        var myAlert = UIAlertController()
        myAlert = UIAlertController(title: "Sign In", message: "Please enter your email and password.", preferredStyle: .alert)
        myAlert.addTextField { (textFields) in
            textFields.placeholder = "email"
        }
        myAlert.addTextField { (textFields) in
            textFields.placeholder = "password"
            textFields.isSecureTextEntry = true
        }
        let submitAction = UIAlertAction(title: "Sign In", style: .default, handler: { (alert) -> Void in
            guard let email = myAlert.textFields![0].text as String? else{
                print("That email is not good")
                return
            }
            guard let password = myAlert.textFields![1].text as String? else{
                print("That password is not good")
                return
            }
            self.signInFirebaseAuth(withEmail: email, password: password)
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in self.welcome()}
        myAlert.addAction(submitAction)
        myAlert.addAction(cancelAction)
        self.present(myAlert, animated: true, completion: nil)
    }
    
    //user auth
    
    func signInFirebaseAuth(withEmail email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            if error == nil {
                self.signInConfirm()
                self.loginName.title = email
            }else{
                self.signInFailed()
            }
        }
    }
    
    func signInConfirm(){
        var savedAlert = UIAlertController()
        savedAlert = UIAlertController(title: "Signing in...", message: "", preferredStyle: .alert)
        self.present(savedAlert, animated: true, completion:nil )
        let when = DispatchTime.now() + 2
        DispatchQueue.main.asyncAfter(deadline: when){
            savedAlert.dismiss(animated: true, completion: nil)
        }
    }
    
    func signInFailed(){
        var savedAlert = UIAlertController()
        savedAlert = UIAlertController(title: "Invalid Email or Incorrect Password!!", message: "", preferredStyle: .alert)
        self.present(savedAlert, animated: true, completion:nil )
        let when = DispatchTime.now() + 2
        DispatchQueue.main.asyncAfter(deadline: when){
            savedAlert.dismiss(animated: true, completion: self.userSignIn)
        }
    }
        
    //MARK: - User Sign Out
    
    func signOut(){
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        self.loginName.title = ""
        
    }
    func signOutConfirm(){
        var savedAlert = UIAlertController()
        savedAlert = UIAlertController(title: "Loggin out...", message: "", preferredStyle: .alert)
        self.present(savedAlert, animated: true, completion:nil )
        let when = DispatchTime.now() + 2
        DispatchQueue.main.asyncAfter(deadline: when){
            savedAlert.dismiss(animated: true, completion: self.welcome)
        }
    }

    @IBAction func logOutButton(_ sender: UIBarButtonItem) {
        signOut()
        signOutConfirm()
    }
}
