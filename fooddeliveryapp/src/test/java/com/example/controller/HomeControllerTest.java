package com.example.controller;

import com.example.model.FoodItem;
import com.example.model.Order;
import com.example.model.User;
import com.example.service.FoodService;
import com.example.service.OrderService;
import jakarta.servlet.http.HttpSession;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.ui.Model;

import java.util.Collections;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class HomeControllerTest {

    @Mock
    private FoodService foodService;

    @Mock
    private OrderService orderService;

    @Mock
    private Model model;

    @Mock
    private HttpSession session;

    @InjectMocks
    private HomeController homeController;

    @Test
    void testHomePageReturnsIndexView() {
        when(foodService.getAllFoodItems()).thenReturn(Collections.emptyList());
        when(session.getAttribute("loggedInUser")).thenReturn(null);

        String viewName = homeController.home(null, model, session);

        assertEquals("index", viewName);
        verify(foodService, times(1)).seedDatabaseIfEmpty();
        verify(model, times(1)).addAttribute(eq("items"), anyList());
        verify(model, times(1)).addAttribute(eq("cartCount"), eq(0));
    }

    @Test
    void testAddToCart() {
        String redirect = homeController.addToCart("Burger", 150.0, "http://img.png");

        assertEquals("redirect:/", redirect);
        List<Order> cart = homeController.getCart();
        assertFalse(cart.isEmpty());
        assertEquals("Burger", cart.get(0).getItemName());
        assertEquals(150.0, cart.get(0).getPrice());
    }

    @Test
    void testCartView() {
        when(orderService.calculateTotal(anyList())).thenReturn(150.0);
        when(session.getAttribute("loggedInUser")).thenReturn(null);

        String viewName = homeController.cart(model, session);

        assertEquals("cart", viewName);
        verify(model, times(1)).addAttribute(eq("total"), eq(150.0));
    }

    @Test
    void testPlaceOrderWithoutLoginRedirectsToLogin() {
        when(session.getAttribute("loggedInUser")).thenReturn(null);

        String redirect = homeController.placeOrder(session);

        assertEquals("redirect:/login", redirect);
    }

    @Test
    void testPlaceOrderWithLoginAndCartRedirectsToPayment() {
        User user = new User();
        user.setName("Test User");
        when(session.getAttribute("loggedInUser")).thenReturn(user);

        homeController.addToCart("Pizza", 299.0, null);
        when(orderService.calculateTotal(anyList())).thenReturn(299.0);

        String redirect = homeController.placeOrder(session);

        assertTrue(redirect.startsWith("redirect:/payment?amount=299.0"));
    }
}
