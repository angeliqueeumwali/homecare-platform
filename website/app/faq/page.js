import PageHero from "@/components/PageHero";

const FAQS = [
  {
    question: "How do I request a service?",
    answer:
      "Register for an account, choose a service category, describe the work, and provide your address and preferred date. A request can include several service items at once.",
  },
  {
    question: "How are providers assigned?",
    answer:
      "The platform matches your request with providers who offer the requested service categories. Matched providers submit quotes, and a provider is assigned when you approve a quote.",
  },
  {
    question: "How do I follow my request?",
    answer:
      "Sign in and open your service requests. Each request shows its current status: pending, in progress, completed or cancelled.",
  },
  {
    question: "What happens after I approve a quote?",
    answer:
      "The quote is marked approved, the provider is assigned to your request, and the work can begin. You can track the status from your account.",
  },
  {
    question: "Can I cancel a request?",
    answer:
      "Yes. Customers can cancel their own requests while they are still active. The status changes to cancelled.",
  },
  {
    question: "How do payments work?",
    answer:
      "Payments are recorded against your request through the platform and reference the approved quote. Available payment methods are shown during the payment step.",
  },
  {
    question: "Can I review a provider?",
    answer:
      "Yes. After a completed assignment, you can rate the provider from 1 to 5 stars and leave a comment.",
  },
  {
    question: "What if something goes wrong with a service?",
    answer:
      "You can report an issue against your request. Issues are tracked with a status of open, under review or resolved, and support staff review them through the admin dashboard.",
  },
  {
    question: "Do I receive an email confirmation?",
    answer:
      "Email delivery is not currently configured. Messages and password reset requests are processed by the platform, but confirmation emails are not sent.",
  },
];

export default function FaqPage() {
  return (
    <>
      <PageHero
        title="Frequently asked questions"
        lead="Answers to the most common questions about requesting services on the platform."
      />
      <div className="container section">
        <dl className="faq-list">
          {FAQS.map((faq) => (
            <div className="faq-item" key={faq.question}>
              <dt>{faq.question}</dt>
              <dd>{faq.answer}</dd>
            </div>
          ))}
        </dl>
      </div>
    </>
  );
}
