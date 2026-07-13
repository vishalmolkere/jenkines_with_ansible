package com.example.employeemanagement.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

import com.example.employeemanagement.entity.Employees;
import com.example.employeemanagement.service.Employeeservice;

@Controller
@RequestMapping("/employees")
public class EmployeeController {

    @Autowired
    Employeeservice empservice;

    @PostMapping("/save")
    public String saveEmployee(@ModelAttribute("employee") Employees emp) {
        empservice.saveEmployee(emp);
        return "redirect:/employees/all";
    }

    @GetMapping("/add")
    public String addemp(Model model) {
        model.addAttribute("employee", new Employees());
        return "addemp";
    }

    @GetMapping("/all")
    public String getAllEmployees(Model model) {
        model.addAttribute("employees", empservice.getAllEmployees());
        return "employees";
    }

    @GetMapping("/edit/{id}")
    public String editEmployee(@PathVariable("id") Long id, Model model) {
        Employees employee = empservice.getEmployeeById(id).orElse(null);
        if (employee == null) {
            return "redirect:/employees/all";
        }
        model.addAttribute("employee", employee);
        return "editEmployee";
    }

    @PostMapping("/update/{id}")
    public String updateEmployee(@PathVariable("id") Long id, @ModelAttribute("employee") Employees emp) {
        Employees updated = empservice.updateEmployee(id, emp);
        if (updated == null) {
            return "redirect:/employees/all?error=notfound";
        }
        return "redirect:/employees/all";
    }

    @PostMapping("/delete/{id}")
    public String deleteEmployee(@PathVariable("id") Long id) {
        empservice.deleteEmployee(id);
        return "redirect:/employees/all";
    }

    @GetMapping("/search")
    public String searchEmployee(
            @RequestParam(value = "name", required = false) String name,
            @RequestParam(value = "phoneno", required = false) String phonenoStr,
            Model model) {

        if (name != null && !name.trim().isEmpty()) {
            model.addAttribute("employees", empservice.searchEmployeesByName(name));
            model.addAttribute("searchTerm", name);
        } else if (phonenoStr != null && !phonenoStr.trim().isEmpty()) {
            try {
                long phoneno = Long.parseLong(phonenoStr.trim());
                model.addAttribute("employees", empservice.searchEmployeesByPhone(phoneno));
                model.addAttribute("searchPhone", phonenoStr.trim());
            } catch (NumberFormatException e) {
                model.addAttribute("employees", empservice.getAllEmployees());
                model.addAttribute("phoneError", "Invalid phone number entered.");
            }
        } else {
            model.addAttribute("employees", empservice.getAllEmployees());
        }
        return "employees";
    }
}
