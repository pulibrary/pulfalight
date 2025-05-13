// Initialize Bootstrap 5 components
document.addEventListener('DOMContentLoaded', function() {
  // Initialize all tooltips
  var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
  var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
    return new bootstrap.Tooltip(tooltipTriggerEl);
  });

  // Initialize all popovers
  var popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'));
  var popoverList = popoverTriggerList.map(function (popoverTriggerEl) {
    return new bootstrap.Popover(popoverTriggerEl);
  });

  // Initialize all modals
  var modalTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="modal"]'));
  modalTriggerList.forEach(function (modalTriggerEl) {
    modalTriggerEl.addEventListener('click', function() {
      var target = this.getAttribute('data-bs-target');
      var modalElement = document.querySelector(target);
      var modalInstance = bootstrap.Modal.getInstance(modalElement) || new bootstrap.Modal(modalElement);
      modalInstance.show();
    });
  });

  // Initialize all collapses
  var collapseTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="collapse"]'));
  collapseTriggerList.forEach(function (collapseTriggerEl) {
    var targetSelector = collapseTriggerEl.getAttribute('data-bs-target') || collapseTriggerEl.getAttribute('href');
    var targetElement = document.querySelector(targetSelector);
    new bootstrap.Collapse(targetElement, { toggle: false });
  });

  // Initialize all tabs
  var tabTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tab"]'));
  tabTriggerList.forEach(function (tabTriggerEl) {
    new bootstrap.Tab(tabTriggerEl);
  });
});